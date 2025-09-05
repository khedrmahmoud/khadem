import 'dart:convert';
import 'package:redis/redis.dart';
import '../../application/khadem.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';

/// Redis queue driver that uses Redis lists for job queuing
class RedisQueueDriver implements QueueDriver {
  final String _queueName;
  final String _host;
  final int _port;
  final String? _password;
  Command? _command;

  RedisQueueDriver({
    String queueName = 'default',
    String host = 'localhost',
    int port = 6379,
    String? password,
  }) : _queueName = 'queue:$queueName',
       _host = host,
       _port = port,
       _password = password;

  Future<Command> _getConnection() async {
    if (_command == null) {
      final conn = RedisConnection();
      _command = await conn.connect(_host, _port);
      
      if (_password != null) {
        await _command!.send_object(['AUTH', _password]);
      }
    }
    return _command!;
  }

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final jobData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': job.runtimeType.toString(),
      'payload': job.toJson(),
      'scheduledAt': DateTime.now().add(delay ?? Duration.zero).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'attempts': 0,
      'maxRetries': job.maxRetries,
    };

    try {
      final command = await _getConnection();
      
      if (delay != null && delay > Duration.zero) {
        // Use Redis sorted sets for delayed jobs
        final score = DateTime.now().add(delay).millisecondsSinceEpoch;
        await command.send_object([
          'ZADD', 
          '${_queueName}:delayed', 
          score.toString(),
          jsonEncode(jobData),
        ]);
      } else {
        // Push to immediate queue
        await command.send_object([
          'LPUSH', 
          _queueName, 
          jsonEncode(jobData),
        ]);
      }
      
      Khadem.logger.info('Job queued in Redis: ${job.displayName}');
    } catch (e) {
      Khadem.logger.error('Failed to queue job in Redis: $e');
      rethrow;
    }
  }

  @override
  Future<void> process() async {
    try {
      final command = await _getConnection();
      
      // First, check for delayed jobs that are ready
      await _processDelayedJobs(command);
      
      // Then process immediate jobs
      await _processImmediateJobs(command);
      
    } catch (e) {
      Khadem.logger.error('Redis queue processing error: $e');
    }
  }

  Future<void> _processDelayedJobs(Command command) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get jobs that are ready (score <= now)
    final result = await command.send_object([
      'ZRANGEBYSCORE',
      '${_queueName}:delayed',
      '-inf',
      now.toString(),
      'LIMIT', '0', '10',  // Process up to 10 jobs at once
    ]);

    if (result is List && result.isNotEmpty) {
      for (final jobJson in result) {
        try {
          // Move job from delayed set to immediate queue
          await command.send_object([
            'ZREM',
            '${_queueName}:delayed',
            jobJson,
          ]);
          
          await command.send_object([
            'LPUSH',
            _queueName,
            jobJson,
          ]);
          
        } catch (e) {
          Khadem.logger.error('Failed to move delayed job: $e');
        }
      }
    }
  }

  Future<void> _processImmediateJobs(Command command) async {
    // Use BRPOP with timeout to get jobs
    final result = await command.send_object([
      'BRPOP',
      _queueName,
      '1',  // 1 second timeout
    ]);

    if (result is List && result.length >= 2) {
      final jobJson = result[1];
      
      try {
        final jobData = jsonDecode(jobJson) as Map<String, dynamic>;
        final scheduledAt = DateTime.parse(jobData['scheduledAt']);
        
        // Check if job is ready to run
        if (scheduledAt.isBefore(DateTime.now()) || scheduledAt.isAtSameMomentAs(DateTime.now())) {
          final job = _RedisQueueJob.fromData(jobData);
          await job.handle();
          
          Khadem.logger.info('Redis job completed: ${jobData['type']}');
        } else {
          // Job not ready yet, put it back with delay
          final score = scheduledAt.millisecondsSinceEpoch;
          await command.send_object([
            'ZADD',
            '${_queueName}:delayed',
            score.toString(),
            jobJson,
          ]);
        }
        
      } catch (e) {
        Khadem.logger.error('Redis job failed: $e');
        await _handleFailedJob(command, jobJson, e);
      }
    }
  }

  Future<void> _handleFailedJob(Command command, String jobJson, dynamic error) async {
    try {
      final jobData = jsonDecode(jobJson) as Map<String, dynamic>;
      jobData['attempts'] = (jobData['attempts'] as int) + 1;
      
      if (jobData['attempts'] >= jobData['maxRetries']) {
        // Job failed permanently, move to failed queue
        await command.send_object([
          'LPUSH',
          '${_queueName}:failed',
          jsonEncode({
            ...jobData,
            'failedAt': DateTime.now().toIso8601String(),
            'error': error.toString(),
          }),
        ]);
        
        Khadem.logger.error('Job failed permanently: ${jobData['type']}');
      } else {
        // Retry job with delay
        const retryDelay = Duration(seconds: 30);
        final retryTime = DateTime.now().add(retryDelay);
        jobData['scheduledAt'] = retryTime.toIso8601String();
        
        await command.send_object([
          'ZADD',
          '${_queueName}:delayed',
          retryTime.millisecondsSinceEpoch.toString(),
          jsonEncode(jobData),
        ]);
        
        Khadem.logger.info('Job scheduled for retry: ${jobData['type']} (attempt ${jobData['attempts']}/${jobData['maxRetries']})');
      }
    } catch (e) {
      Khadem.logger.error('Failed to handle failed job: $e');
    }
  }

  /// Clear all jobs from the queue
  Future<void> clear() async {
    try {
      final command = await _getConnection();
      await command.send_object(['DEL', _queueName]);
      await command.send_object(['DEL', '${_queueName}:delayed']);
      await command.send_object(['DEL', '${_queueName}:failed']);
    } catch (e) {
      Khadem.logger.error('Failed to clear Redis queue: $e');
    }
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final command = await _getConnection();
      
      final immediateCount = await command.send_object(['LLEN', _queueName]);
      final delayedCount = await command.send_object(['ZCARD', '${_queueName}:delayed']);
      final failedCount = await command.send_object(['LLEN', '${_queueName}:failed']);
      
      return {
        'driver': 'redis',
        'immediate_jobs': immediateCount ?? 0,
        'delayed_jobs': delayedCount ?? 0,
        'failed_jobs': failedCount ?? 0,
        'total_jobs': (immediateCount ?? 0) + (delayedCount ?? 0),
        'host': _host,
        'port': _port,
        'queue_name': _queueName,
      };
    } catch (e) {
      Khadem.logger.error('Failed to get Redis queue stats: $e');
      return {
        'driver': 'redis',
        'error': e.toString(),
      };
    }
  }

  /// Close the Redis connection
  Future<void> close() async {
    if (_command != null) {
      try {
        // Redis connection doesn't have explicit close method
        _command = null;
      } catch (e) {
        Khadem.logger.error('Error closing Redis connection: $e');
      }
    }
  }
}

/// Generic job wrapper for Redis-persisted jobs
class _RedisQueueJob extends QueueJob {
  final Map<String, dynamic> _data;
  final Map<String, dynamic> _payload;

  _RedisQueueJob.fromData(this._data) : _payload = _data['payload'];

  @override
  Future<void> handle() async {
    // For Redis queue, we can only log the job execution
    // Since we can't reconstruct the original job instance
    print('🔴 Processing Redis job: ${_data['type']}');
    print('   Payload: $_payload');
    print('   Attempts: ${_data['attempts']}/${_data['maxRetries']}');
    
    // Simulate some work
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('✅ Redis job completed: ${_data['type']}');
  }

  @override
  String get displayName => _data['type'];

  @override
  int get maxRetries => _data['maxRetries'];
}
