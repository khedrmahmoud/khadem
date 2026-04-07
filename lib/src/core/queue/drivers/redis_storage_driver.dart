import 'dart:convert';

import 'package:redis/redis.dart';

import '../../../contracts/queue/queue_job.dart';
import '../../../support/exceptions/queue_exception.dart';
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
  final Set<String> _allowedJobTypes;
  final int _maxPayloadDepth;
  final int _maxPayloadNodes;
  final int _maxSerializedJobBytes;
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
    Set<String>? allowedJobTypes,
    int maxPayloadDepth = 10,
    int maxPayloadNodes = 2000,
    int maxSerializedJobBytes = 1024 * 1024,
  }) : host =
           host ??
           config.driverSpecificConfig['host'] as String? ??
           'localhost',
       port = port ?? config.driverSpecificConfig['port'] as int? ?? 6379,
       password =
           password ?? config.driverSpecificConfig['password'] as String?,
       queueName =
           queueName ??
           config.driverSpecificConfig['queueName'] as String? ??
           'default',
       _allowedJobTypes =
           allowedJobTypes ??
           _parseAllowedJobTypes(
             config.driverSpecificConfig['allowedJobTypes'],
           ),
       _maxPayloadDepth = maxPayloadDepth,
       _maxPayloadNodes = maxPayloadNodes,
       _maxSerializedJobBytes = maxSerializedJobBytes;

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
    final jobType = job.runtimeType.toString();
    _validateJobType(jobType);

    final payload = _asMap(job.toJson()) ?? <String, dynamic>{};
    if (!_isSafePayload(payload)) {
      throw QueueException('Rejected unsafe job payload for type $jobType');
    }

    final context = createJobContext(job, delay: delay);
    final command = await _getConnection();

    final jobData = {...context.toJson(), 'payload': payload};

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
        await command.send_object(['LPUSH', _mainQueue, jsonEncode(jobData)]);
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

      final jobJson = _asString(result[1]);
      if (jobJson == null || jobJson.isEmpty) {
        throw QueueException('Invalid Redis queue payload: empty job data');
      }

      if (utf8.encode(jobJson).length > _maxSerializedJobBytes) {
        throw QueueException(
          'Invalid Redis queue payload: job envelope too large',
        );
      }

      final decoded = jsonDecode(jobJson);
      if (decoded is! Map) {
        throw QueueException('Invalid Redis queue payload: expected JSON map');
      }

      final jobData = _asMap(decoded) ?? <String, dynamic>{};
      final jobId = _asString(jobData['id']);
      if (jobId == null || jobId.isEmpty) {
        throw QueueException('Invalid Redis queue payload: missing job id');
      }

      // Store in processing hash
      await command.send_object(['HSET', _processingHash, jobId, jobJson]);

      try {
        // Recreate job from registry
        final jobType = _asString(jobData['jobType']);
        final payload = _asMap(jobData['payload']);

        if (jobType == null || payload == null) {
          throw QueueException(
            'Invalid Redis queue payload: missing jobType or payload',
          );
        }

        _validateJobType(jobType);

        if (!_isSafePayload(payload)) {
          throw QueueException('Rejected unsafe job payload for type $jobType');
        }

        if (!QueueJobRegistry.isRegistered(jobType)) {
          throw QueueException(
            'Job type "$jobType" not registered in QueueJobRegistry',
          );
        }

        final job = QueueJobRegistry.create(jobType, payload);
        final context = _createContextFromData(job, jobData);

        await executeJob(context);

        // Remove from processing hash
        await command.send_object(['HDEL', _processingHash, jobId]);
      } catch (e, stack) {
        final fallbackJobType = _asString(jobData['jobType']);
        final fallbackPayload = _asMap(jobData['payload']);
        if (fallbackJobType == null || fallbackPayload == null) {
          throw QueueException(
            'Invalid Redis queue payload during failure handling',
          );
        }

        // Handle failure
        final context = _createContextFromData(
          QueueJobRegistry.create(fallbackJobType, fallbackPayload),
          jobData,
        );
        context.error = e;
        context.stackTrace = stack;

        await handleJobFailure(context);

        // Remove from processing hash
        await command.send_object(['HDEL', _processingHash, jobId]);
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

  JobContext _createContextFromData(QueueJob job, Map<String, dynamic> data) {
    final id =
        _asString(data['id']) ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final queuedAt = _asDateTime(data['queuedAt']) ?? DateTime.now();
    final scheduledFor = _asDateTime(data['scheduledFor']);
    final attempts = _asInt(data['attempts']);
    final statusName = _asString(data['status']);

    return JobContext(
      id: id,
      job: job,
      queuedAt: queuedAt,
      scheduledFor: scheduledFor,
      attempts: attempts,
      status: JobStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => JobStatus.pending,
      ),
      metadata: _asMap(data['metadata']) ?? <String, dynamic>{},
    );
  }

  @override
  Future<void> retryJob(JobContext context, {required Duration delay}) async {
    final command = await _getConnection();

    final jobData = {...context.toJson(), 'payload': context.job.toJson()};

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

    await command.send_object(['LPUSH', _failedQueue, jsonEncode(jobData)]);
  }

  Future<int> _getQueueDepth() async {
    final command = await _getConnection();

    final mainCount = await command.send_object(['LLEN', _mainQueue]);
    final delayedCount = await command.send_object(['ZCARD', _delayedQueue]);

    return _asInt(mainCount) + _asInt(delayedCount);
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
      return _asString(result) == 'PONG';
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
      final processingCount = await command.send_object([
        'HLEN',
        _processingHash,
      ]);
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
          'main_jobs': _asInt(mainCount),
          'delayed_jobs': _asInt(delayedCount),
          'processing_jobs': _asInt(processingCount),
          'failed_jobs': _asInt(failedCount),
          'total_jobs': _asInt(mainCount) + _asInt(delayedCount),
        },
      };
    } catch (e) {
      return {...baseStats, 'error': e.toString()};
    }
  }

  @override
  Future<void> dispose() async {
    _isConnected = false;
    _command = null;
    await super.dispose();
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    if (value is List<int>) {
      return utf8.decode(value);
    }

    return value.toString();
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  DateTime? _asDateTime(dynamic value) {
    final text = _asString(value);
    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
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
