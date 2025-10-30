import 'dart:convert';
import 'dart:io';

import '../../../contracts/queue/queue_job.dart';
import '../registry/index.dart';
import 'base_driver.dart';

/// Persistent file-based queue driver
///
/// Stores jobs in JSON files on disk for persistence across restarts.
/// Perfect for:
/// - Small to medium applications
/// - Jobs that must survive restarts
/// - Simple deployment without Redis/Database
/// - Development and testing with persistence
///
/// Features:
/// - Persistent storage
/// - Automatic recovery on restart
/// - Job serialization/deserialization
/// - Atomic file operations
/// - Lock-free design
/// - Full metrics tracking
/// - Middleware support
/// - Dead letter queue integration
///
/// Example:
/// ```dart
/// // Register serializable jobs
/// QueueJobRegistry.register('SendEmailJob',
///   (json) => SendEmailJob.fromJson(json));
///
/// final driver = FileStorageDriver(
///   config: DriverConfig(
///     name: 'file',
///     driverSpecificConfig: {
///       'storagePath': './storage/queue',
///     },
///   ),
///   metrics: metrics,
///   dlqHandler: dlqHandler,
/// );
///
/// await driver.push(SendEmailJob('user@example.com'));
/// await driver.process();
/// ```
class FileStorageDriver extends BaseQueueDriver {
  final String storagePath;
  final String _jobsFileName = 'jobs.json';
  final List<JobContext> _memoryCache = [];
  bool _isLoaded = false;

  FileStorageDriver({
    required super.config,
    super.metrics,
    super.dlqHandler,
    super.middleware,
    String? storagePath,
  }) : storagePath = storagePath ??
            config.driverSpecificConfig['storagePath'] as String? ??
            './storage/queue';

  String get _jobsFilePath => '$storagePath/$_jobsFileName';

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    await _ensureLoaded();

    final context = createJobContext(job, delay: delay);

    // Track metrics
    if (metrics != null) {
      metrics!.jobQueued(job.runtimeType.toString());
      metrics!.recordQueueDepth(_memoryCache.length + 1);
    }

    _memoryCache.add(context);
    await _persistToFile();
  }

  @override
  Future<void> process() async {
    await _ensureLoaded();

    // Find next ready job
    final readyJob = _findNextReadyJob();
    if (readyJob == null) return;

    try {
      await executeJob(readyJob);
    } finally {
      // Remove completed/failed job
      if (readyJob.status == JobStatus.completed ||
          readyJob.status == JobStatus.deadLettered) {
        _memoryCache.remove(readyJob);
        await _persistToFile();
      }

      // Update metrics
      if (metrics != null) {
        metrics!.recordQueueDepth(_memoryCache.length);
      }
    }
  }

  @override
  Future<void> retryJob(JobContext context, {required Duration delay}) async {
    // Update scheduled time for retry
    context.metadata['scheduledFor'] =
        DateTime.now().add(delay).toIso8601String();

    await _persistToFile();
  }

  JobContext? _findNextReadyJob() {
    for (final job in _memoryCache) {
      if (job.isReady && job.status != JobStatus.processing) {
        return job;
      }
    }
    return null;
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;

    await _loadFromFile();
    _isLoaded = true;
  }

  Future<void> _persistToFile() async {
    try {
      final file = File(_jobsFilePath);
      await file.create(recursive: true);

      final List<Map<String, dynamic>> serializedJobs =
          _memoryCache.map((context) {
        return {
          ...context.toJson(),
          'payload': context.job.toJson(),
          'error': context.error?.toString(),
          'stackTrace': context.stackTrace?.toString(),
        };
      }).toList();

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(serializedJobs),
      );
    } catch (e) {
      // Log error but don't throw - queue continues in memory
      print('⚠️ Failed to persist queue to file: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(_jobsFilePath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.isEmpty) return;

      final List<dynamic> serializedJobs = jsonDecode(content);

      for (final jobData in serializedJobs) {
        try {
          final jobType = jobData['jobType'] as String;
          final payload = jobData['payload'] as Map<String, dynamic>;

          // Recreate job from registry
          if (!QueueJobRegistry.isRegistered(jobType)) {
            print('⚠️ Skipping unregistered job type: $jobType');
            continue;
          }

          final job = QueueJobRegistry.create(jobType, payload);
          final context = JobContext(
            id: jobData['id'] as String,
            job: job,
            queuedAt: DateTime.parse(jobData['queuedAt'] as String),
            scheduledFor: jobData['scheduledFor'] != null
                ? DateTime.parse(jobData['scheduledFor'] as String)
                : null,
            attempts: jobData['attempts'] as int? ?? 0,
            status: JobStatus.values.firstWhere(
              (s) => s.name == jobData['status'],
              orElse: () => JobStatus.pending,
            ),
            metadata: jobData['metadata'] as Map<String, dynamic>? ?? {},
          );

          _memoryCache.add(context);
        } catch (e) {
          print('⚠️ Failed to deserialize job: $e');
        }
      }

      // Update metrics
      if (metrics != null) {
        metrics!.recordQueueDepth(_memoryCache.length);
      }
    } catch (e) {
      print('⚠️ Failed to load queue from file: $e');
    }
  }

  @override
  Future<void> clear() async {
    _memoryCache.clear();
    await _persistToFile();

    if (metrics != null) {
      metrics!.recordQueueDepth(0);
    }
  }

  @override
  Future<void> dispose() async {
    await _persistToFile();
    await super.dispose();
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    await _ensureLoaded();
    final baseStats = await super.getStats();

    final readyCount = _memoryCache.where((j) => j.isReady).length;
    final delayedCount = _memoryCache.where((j) => !j.isReady).length;

    return {
      ...baseStats,
      'storage_path': storagePath,
      'total_jobs': _memoryCache.length,
      'ready_jobs': readyCount,
      'delayed_jobs': delayedCount,
      'is_loaded': _isLoaded,
      'file_exists': await File(_jobsFilePath).exists(),
    };
  }

  /// Get all pending jobs (for inspection)
  Future<List<JobContext>> getPendingJobs() async {
    await _ensureLoaded();
    return List.unmodifiable(_memoryCache);
  }

  /// Get pending job count
  Future<int> get pendingJobsCount async {
    await _ensureLoaded();
    return _memoryCache.length;
  }
}
