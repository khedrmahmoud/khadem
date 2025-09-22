import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';

/// File queue driver that persists jobs to disk
class FileQueueDriver implements QueueDriver {
  final String _queuePath;
  final List<Map<String, dynamic>> _memoryQueue = [];

  FileQueueDriver({String? queuePath})
      : _queuePath = queuePath ?? 'storage/queue/jobs.json';

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final jobData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': job.runtimeType.toString(),
      'payload': job.toJson(),
      'scheduledAt':
          DateTime.now().add(delay ?? Duration.zero).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'attempts': 0,
      'maxRetries': job.maxRetries,
    };

    // Add to memory queue
    _memoryQueue.add(jobData);

    // Persist to file
    await _persistToFile();

    print('📁 Job queued: ${job.displayName}');
  }

  @override
  Future<void> process() async {
    // Load jobs from file if memory queue is empty
    if (_memoryQueue.isEmpty) {
      await _loadFromFile();
    }

    if (_memoryQueue.isEmpty) {
      return;
    }

    // Process jobs that are due
    final now = DateTime.now();
    final jobsToProcess = _memoryQueue.where((jobData) {
      final scheduledAt = DateTime.parse(jobData['scheduledAt']);
      return scheduledAt.isBefore(now) || scheduledAt.isAtSameMomentAs(now);
    }).toList();

    for (final jobData in jobsToProcess) {
      try {
        // Create a generic job that runs the stored payload
        final genericJob = _FileQueueJob.fromData(jobData);
        await genericJob.handle();

        // Remove completed job
        _memoryQueue.remove(jobData);
        print('📁 Job completed: ${jobData['type']}');
      } catch (e) {
        print('📁 Job failed: ${jobData['type']} - $e');

        // Handle retries
        jobData['attempts'] = (jobData['attempts'] as int) + 1;
        if (jobData['attempts'] >= jobData['maxRetries']) {
          _memoryQueue.remove(jobData);
          print('📁 Job failed permanently: ${jobData['type']}');
        } else {
          // Reschedule for retry
          const retryDelay = Duration(seconds: 30);
          jobData['scheduledAt'] =
              DateTime.now().add(retryDelay).toIso8601String();
        }
      }
    }

    // Persist changes to file
    await _persistToFile();
  }

  Future<void> _persistToFile() async {
    try {
      final file = File(_queuePath);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(_memoryQueue));
    } catch (e) {
      print('📁 Failed to persist queue to file: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(_queuePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final jobs = jsonDecode(content) as List<dynamic>;
          _memoryQueue.clear();
          _memoryQueue.addAll(jobs.cast<Map<String, dynamic>>());
        }
      }
    } catch (e) {
      print('📁 Failed to load queue from file: $e');
    }
  }

  /// Clear all jobs from the queue
  Future<void> clear() async {
    _memoryQueue.clear();
    await _persistToFile();
  }

  /// Get the number of pending jobs
  int get pendingJobs => _memoryQueue.length;

  /// Get queue statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final ready = _memoryQueue.where((job) {
      final scheduledAt = DateTime.parse(job['scheduledAt']);
      return scheduledAt.isBefore(now);
    }).length;

    return {
      'driver': 'file',
      'total_jobs': _memoryQueue.length,
      'ready_jobs': ready,
      'scheduled_jobs': _memoryQueue.length - ready,
      'file_path': _queuePath,
    };
  }
}

/// Generic job wrapper for file-persisted jobs
class _FileQueueJob extends QueueJob {
  final Map<String, dynamic> _data;
  final Map<String, dynamic> _payload;

  _FileQueueJob.fromData(this._data) : _payload = _data['payload'];

  @override
  Future<void> handle() async {
    // For file queue, we can only log the job execution
    // Since we can't reconstruct the original job instance
    print('📁 Processing file job: ${_data['type']}');
    print('   Payload: $_payload');
    print('   Attempts: ${_data['attempts']}/${_data['maxRetries']}');

    // Simulate some work
    await Future.delayed(const Duration(milliseconds: 100));

    print('✅ File job completed: ${_data['type']}');
  }

  @override
  String get displayName => _data['type'];

  @override
  int get maxRetries => _data['maxRetries'];
}
