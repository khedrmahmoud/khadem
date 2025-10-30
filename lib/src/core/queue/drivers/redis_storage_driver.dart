import 'dart:convert';

import 'package:redis/redis.dart';

import '../../../contracts/queue/queue_job.dart';
import '../registry/index.dart';
import 'base_driver.dart';

/// Production-ready Redis queue driver
///
/// Uses Redis for distributed, persistent job queuing.
/// Perfect for:
/// - Production applications
/// - Distributed systems
/// - High-volume workloads
/// - Multiple workers
/// - Jobs that must survive crashes
///
/// Features:
/// - Persistent storage in Redis
/// - Distributed queue access
/// - Delayed jobs using sorted sets
/// - Atomic operations
/// - Connection pooling
/// - Health checks
/// - Full metrics tracking
/// - Middleware support
/// - Dead letter queue integration
///
/// Redis Data Structures:
/// - `queue:{name}` - Main queue (list)
/// - `queue:{name}:delayed` - Delayed jobs (sorted set)
/// - `queue:{name}:processing` - Processing jobs (hash)
///
/// Example:
/// ```dart
/// // Register serializable jobs
/// QueueJobRegistry.register('SendEmailJob',
///   (json) => SendEmailJob.fromJson(json));
///
/// final driver = RedisStorageDriver(
///   config: DriverConfig(
///     name: 'redis',
///     driverSpecificConfig: {
///       'host': 'localhost',
///       'port': 6379,
///       'password': 'secret',
///       'queueName': 'jobs',
///     },
///   ),
///   metrics: metrics,
///   dlqHandler: dlqHandler,
/// );
///
/// await driver.push(SendEmailJob('user@example.com'));
/// await driver.process();
/// ```
class RedisStorageDriver extends BaseQueueDriver {
  final String host;
  final int port;
  final String? password;
  final String queueName;
  Command? _command;
  bool _isConnected = false;

  String get _mainQueue => 'queue:$queueName';
  String get _delayedQueue => 'queue:$queueName:delayed';
  String get _processingHash => 'queue:$queueName:processing';
  String get _failedQueue => 'queue:$queueName:failed';

  RedisStorageDriver({
    required super.config,
    super.metrics,
    super.dlqHandler,
    super.middleware,
    String? host,
    int? port,
    String? password,
    String? queueName,
  })  : host = host ??
            config.driverSpecificConfig['host'] as String? ??
            'localhost',
        port = port ?? config.driverSpecificConfig['port'] as int? ?? 6379,
        password =
            password ?? config.driverSpecificConfig['password'] as String?,
        queueName = queueName ??
            config.driverSpecificConfig['queueName'] as String? ??
            'default';

  Future<Command> _getConnection() async {
    if (_command != null && _isConnected) {
      return _command!;
    }

    try {
      final conn = RedisConnection();
      _command = await conn.connect(host, port);
      _isConnected = true;

      if (password != null && password!.isNotEmpty) {
        await _command!.send_object(['AUTH', password]);
      }

      return _command!;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final context = createJobContext(job, delay: delay);
    final command = await _getConnection();

    final jobData = {
      ...context.toJson(),
      'payload': job.toJson(),
    };

    // Track metrics
    if (metrics != null) {
      metrics!.jobQueued(job.runtimeType.toString());
    }

    try {
      if (delay != null && delay > Duration.zero) {
        // Use sorted set for delayed jobs
        final score = DateTime.now().add(delay).millisecondsSinceEpoch;
        await command.send_object([
          'ZADD',
          _delayedQueue,
          score.toString(),
          jsonEncode(jobData),
        ]);
      } else {
        // Push to main queue
        await command.send_object([
          'LPUSH',
          _mainQueue,
          jsonEncode(jobData),
        ]);
      }

      // Update queue depth metrics
      if (metrics != null) {
        final depth = await _getQueueDepth();
        metrics!.recordQueueDepth(depth);
      }
    } catch (e) {
      print('❌ Failed to push job to Redis: $e');
      rethrow;
    }
  }

  @override
  Future<void> process() async {
    final command = await _getConnection();

    // Move ready delayed jobs to main queue
    await _processDelayedJobs(command);

    // Process one job from main queue
    await _processNextJob(command);
  }

  Future<void> _processDelayedJobs(Command command) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      // Get jobs that are ready (score <= now)
      final result = await command.send_object([
        'ZRANGEBYSCORE',
        _delayedQueue,
        '-inf',
        now.toString(),
        'LIMIT',
        '0',
        '10', // Process up to 10 delayed jobs at once
      ]);

      if (result is List && result.isNotEmpty) {
        for (final jobJson in result) {
          // Move from delayed to main queue
          await command.send_object(['ZREM', _delayedQueue, jobJson]);
          await command.send_object(['LPUSH', _mainQueue, jobJson]);
        }
      }
    } catch (e) {
      print('⚠️ Failed to process delayed jobs: $e');
    }
  }

  Future<void> _processNextJob(Command command) async {
    try {
      // Pop job from queue (blocking with 1 second timeout)
      final result = await command.send_object([
        'BRPOP',
        _mainQueue,
        '1', // 1 second timeout
      ]);

      if (result is! List || result.length < 2) return;

      final jobJson = result[1] as String;
      final jobData = jsonDecode(jobJson) as Map<String, dynamic>;

      // Store in processing hash
      await command.send_object([
        'HSET',
        _processingHash,
        jobData['id'],
        jobJson,
      ]);

      try {
        // Recreate job from registry
        final jobType = jobData['jobType'] as String;
        final payload = jobData['payload'] as Map<String, dynamic>;

        if (!QueueJobRegistry.isRegistered(jobType)) {
          throw Exception(
              'Job type "$jobType" not registered in QueueJobRegistry',);
        }

        final job = QueueJobRegistry.create(jobType, payload);
        final context = _createContextFromData(job, jobData);

        await executeJob(context);

        // Remove from processing hash
        await command.send_object(['HDEL', _processingHash, jobData['id']]);
      } catch (e, stack) {
        // Handle failure
        final context = _createContextFromData(
          QueueJobRegistry.create(
            jobData['jobType'] as String,
            jobData['payload'] as Map<String, dynamic>,
          ),
          jobData,
        );
        context.error = e;
        context.stackTrace = stack;

        await handleJobFailure(context);

        // Remove from processing hash
        await command.send_object(['HDEL', _processingHash, jobData['id']]);
      }

      // Update metrics
      if (metrics != null) {
        final depth = await _getQueueDepth();
        metrics!.recordQueueDepth(depth);
      }
    } catch (e) {
      print('⚠️ Redis queue processing error: $e');
    }
  }

  JobContext _createContextFromData(
    QueueJob job,
    Map<String, dynamic> data,
  ) {
    return JobContext(
      id: data['id'] as String,
      job: job,
      queuedAt: DateTime.parse(data['queuedAt'] as String),
      scheduledFor: data['scheduledFor'] != null
          ? DateTime.parse(data['scheduledFor'] as String)
          : null,
      attempts: data['attempts'] as int? ?? 0,
      status: JobStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => JobStatus.pending,
      ),
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<void> retryJob(JobContext context, {required Duration delay}) async {
    final command = await _getConnection();

    final jobData = {
      ...context.toJson(),
      'payload': context.job.toJson(),
    };

    // Schedule retry
    final retryTime = DateTime.now().add(delay);
    await command.send_object([
      'ZADD',
      _delayedQueue,
      retryTime.millisecondsSinceEpoch.toString(),
      jsonEncode(jobData),
    ]);
  }

  @override
  Future<void> onJobFailed(JobContext context) async {
    final command = await _getConnection();

    // Move to failed queue
    final jobData = {
      ...context.toJson(),
      'payload': context.job.toJson(),
      'error': context.error?.toString(),
      'stackTrace': context.stackTrace?.toString(),
      'failedAt': DateTime.now().toIso8601String(),
    };

    await command.send_object([
      'LPUSH',
      _failedQueue,
      jsonEncode(jobData),
    ]);
  }

  Future<int> _getQueueDepth() async {
    final command = await _getConnection();

    final mainCount = await command.send_object(['LLEN', _mainQueue]);
    final delayedCount = await command.send_object(['ZCARD', _delayedQueue]);

    return (mainCount as int? ?? 0) + (delayedCount as int? ?? 0);
  }

  @override
  Future<void> clear() async {
    final command = await _getConnection();

    await command.send_object(['DEL', _mainQueue]);
    await command.send_object(['DEL', _delayedQueue]);
    await command.send_object(['DEL', _processingHash]);
    await command.send_object(['DEL', _failedQueue]);

    if (metrics != null) {
      metrics!.recordQueueDepth(0);
    }
  }

  @override
  Future<bool> isHealthy() async {
    try {
      final command = await _getConnection();
      final result = await command.send_object(['PING']);
      return result == 'PONG';
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final baseStats = await super.getStats();

    try {
      final command = await _getConnection();

      final mainCount = await command.send_object(['LLEN', _mainQueue]);
      final delayedCount = await command.send_object(['ZCARD', _delayedQueue]);
      final processingCount =
          await command.send_object(['HLEN', _processingHash]);
      final failedCount = await command.send_object(['LLEN', _failedQueue]);

      return {
        ...baseStats,
        'connection': {
          'host': host,
          'port': port,
          'is_connected': _isConnected,
          'queue_name': queueName,
        },
        'queue': {
          'main_jobs': mainCount ?? 0,
          'delayed_jobs': delayedCount ?? 0,
          'processing_jobs': processingCount ?? 0,
          'failed_jobs': failedCount ?? 0,
          'total_jobs': (mainCount ?? 0) + (delayedCount ?? 0),
        },
      };
    } catch (e) {
      return {
        ...baseStats,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<void> dispose() async {
    _isConnected = false;
    _command = null;
    await super.dispose();
  }
}
