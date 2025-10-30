import 'dart:convert';
import '../../../contracts/queue/dlq/dead_letter_queue_contract.dart';
import '../../../contracts/queue/dlq/failed_job.dart';
import '../../../contracts/queue/dlq/failed_job_handler_contract.dart';

/// Handler for managing failed jobs and retry logic
class FailedJobHandler implements FailedJobHandlerContract {
  final DeadLetterQueue _dlq;

  FailedJobHandler(this._dlq);

  @override
  Future<void> recordFailure({
    required String id,
    required String jobType,
    required Map<String, dynamic> payload,
    required dynamic error,
    required int attempts,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    final failedJob = FailedJob(
      id: id,
      jobType: jobType,
      payload: payload,
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      failedAt: DateTime.now(),
      attempts: attempts,
      metadata: metadata,
    );

    await _dlq.store(failedJob);
  }

  @override
  Future<FailedJob?> retry(String id) async {
    final job = await _dlq.get(id);
    if (job != null) {
      await _dlq.remove(id);
    }
    return job;
  }

  @override
  Future<List<FailedJob>> retryByType(String jobType) async {
    final jobs = await _dlq.getByType(jobType);
    for (final job in jobs) {
      await _dlq.remove(job.id);
    }
    return jobs;
  }

  @override
  Future<int> prune({Duration? olderThan}) async {
    final cutoff =
        DateTime.now().subtract(olderThan ?? const Duration(days: 7));
    final oldJobs = await _dlq.getByDateRange(
      DateTime.fromMillisecondsSinceEpoch(0),
      cutoff,
    );

    for (final job in oldJobs) {
      await _dlq.remove(job.id);
    }

    return oldJobs.length;
  }

  @override
  Future<Map<String, dynamic>> getReport() async {
    final stats = await _dlq.getStats();
    final recentFailures = await _dlq.getAll(limit: 10);

    return {
      'stats': stats,
      'recentFailures': recentFailures.map((j) => j.toJson()).toList(),
    };
  }

  @override
  Future<String> exportToJson({int? limit}) async {
    final jobs = await _dlq.getAll(limit: limit);
    return jsonEncode(jobs.map((j) => j.toJson()).toList());
  }

  /// Get the DLQ instance
  DeadLetterQueue get dlq => _dlq;
}
