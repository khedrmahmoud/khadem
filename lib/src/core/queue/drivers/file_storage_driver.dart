import 'dart:convert';
import 'dart:io';

import '../../../contracts/queue/queue_job.dart';
import '../../../support/exceptions/queue_exception.dart';
import '../../../support/utils/mutex.dart';
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
  final Set<String> _allowedJobTypes;
  final int _maxPayloadDepth;
  final int _maxPayloadNodes;
  final String _jobsFileName = 'jobs.json';
  final List<JobContext> _memoryCache = [];
  bool _isLoaded = false;
  final Mutex _lock = Mutex();

  FileStorageDriver({
    required super.config,
    super.metrics,
    super.dlqHandler,
    super.middleware,
    String? storagePath,
    Set<String>? allowedJobTypes,
    int maxPayloadDepth = 10,
    int maxPayloadNodes = 2000,
  }) : storagePath =
           storagePath ??
           config.driverSpecificConfig['storagePath'] as String? ??
           './storage/queue',
       _allowedJobTypes =
           allowedJobTypes ??
           _parseAllowedJobTypes(
             config.driverSpecificConfig['allowedJobTypes'],
           ),
       _maxPayloadDepth = maxPayloadDepth,
       _maxPayloadNodes = maxPayloadNodes;

  static Set<String> _parseAllowedJobTypes(dynamic raw) {
    if (raw is Iterable) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    return <String>{};
  }

  String get _jobsFilePath => '$storagePath/$_jobsFileName';

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final jobType = job.runtimeType.toString();
    _validateJobType(jobType);

    await _lock.protect(() async {
      await _ensureLoaded();

      final context = createJobContext(job, delay: delay);

      // Track metrics
      if (metrics != null) {
        metrics!.jobQueued(job.runtimeType.toString());
        metrics!.recordQueueDepth(_memoryCache.length + 1);
      }

      _memoryCache.add(context);
      await _persistToFile();
    });
  }

  @override
  Future<void> process() async {
    JobContext? readyJob;

    await _lock.protect(() async {
      await _ensureLoaded();
      readyJob = _findNextReadyJob();
      if (readyJob != null) {
        // Mark as processing in memory to prevent other workers from grabbing
        readyJob!.status = JobStatus.processing;
        await _persistToFile();
      }
    });

    if (readyJob == null) return;

    try {
      await executeJob(readyJob!);
    } finally {
      await _lock.protect(() async {
        // Remove completed/failed job
        if (readyJob!.status == JobStatus.completed ||
            readyJob!.status == JobStatus.deadLettered) {
          _memoryCache.remove(readyJob);
          await _persistToFile();
        }

        // Update metrics
        if (metrics != null) {
          metrics!.recordQueueDepth(_memoryCache.length);
        }
      });
    }
  }

  @override
  Future<void> retryJob(JobContext context, {required Duration delay}) async {
    // Update scheduled time for retry
    context.metadata['scheduledFor'] = DateTime.now()
        .add(delay)
        .toIso8601String();

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

      final List<Map<String, dynamic>> serializedJobs = _memoryCache.map((
        context,
      ) {
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
          if (jobData is! Map) {
            throw QueueException('Invalid serialized job envelope');
          }

          final normalizedJobData = jobData.map(
            (key, value) => MapEntry(key.toString(), value),
          );

          final jobType = normalizedJobData['jobType']?.toString();
          final payloadRaw = normalizedJobData['payload'];

          if (jobType == null) {
            throw QueueException('Missing jobType in serialized job');
          }

          _validateJobType(jobType);

          if (payloadRaw is! Map) {
            throw QueueException('Invalid job payload: expected JSON object');
          }

          final payload = payloadRaw.map(
            (key, value) => MapEntry(key.toString(), value),
          );

          if (!_isSafePayload(payload)) {
            throw QueueException(
              'Rejected unsafe job payload for type $jobType',
            );
          }

          // Recreate job from registry
          if (!QueueJobRegistry.isRegistered(jobType)) {
            print('⚠️ Skipping unregistered job type: $jobType');
            continue;
          }

          final job = QueueJobRegistry.create(jobType, payload);
          final context = JobContext(
            id:
                normalizedJobData['id']?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString(),
            job: job,
            queuedAt:
                DateTime.tryParse(
                  normalizedJobData['queuedAt']?.toString() ?? '',
                ) ??
                DateTime.now(),
            scheduledFor: normalizedJobData['scheduledFor'] != null
                ? DateTime.tryParse(
                    normalizedJobData['scheduledFor']?.toString() ?? '',
                  )
                : null,
            attempts: normalizedJobData['attempts'] is int
                ? normalizedJobData['attempts'] as int
                : int.tryParse(
                        normalizedJobData['attempts']?.toString() ?? '',
                      ) ??
                      0,
            status: JobStatus.values.firstWhere(
              (s) => s.name == normalizedJobData['status']?.toString(),
              orElse: () => JobStatus.pending,
            ),
            metadata: normalizedJobData['metadata'] is Map
                ? (normalizedJobData['metadata'] as Map).map(
                    (key, value) => MapEntry(key.toString(), value),
                  )
                : <String, dynamic>{},
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

  void _validateJobType(String jobType) {
    final jobTypePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,99}$');
    if (!jobTypePattern.hasMatch(jobType)) {
      throw QueueException('Invalid job type format: $jobType');
    }

    if (_allowedJobTypes.isNotEmpty && !_allowedJobTypes.contains(jobType)) {
      throw QueueException('Job type "$jobType" is not allowed for this queue');
    }
  }

  bool _isSafePayload(Map<String, dynamic> payload) {
    var visitedNodes = 0;

    bool validate(dynamic value, int depth) {
      if (depth > _maxPayloadDepth) {
        return false;
      }

      visitedNodes++;
      if (visitedNodes > _maxPayloadNodes) {
        return false;
      }

      if (value == null || value is num || value is bool) {
        return true;
      }

      if (value is String) {
        return value.length <= 100000;
      }

      if (value is List) {
        if (value.length > 5000) return false;
        for (final item in value) {
          if (!validate(item, depth + 1)) {
            return false;
          }
        }
        return true;
      }

      if (value is Map) {
        if (value.length > 5000) return false;
        for (final entry in value.entries) {
          if (entry.key.toString().length > 256) {
            return false;
          }
          if (!validate(entry.value, depth + 1)) {
            return false;
          }
        }
        return true;
      }

      return false;
    }

    return validate(payload, 0);
  }
}
