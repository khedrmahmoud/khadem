import 'failed_job.dart';

/// Interface for handling failed jobs and retry logic
abstract interface class FailedJobHandlerContract {
  /// Record a job failure
  Future<void> recordFailure({
    required String id,
    required String jobType,
    required Map<String, dynamic> payload,
    required dynamic error,
    required int attempts,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  });

  /// Retry a failed job (returns the job for re-dispatch)
  Future<FailedJob?> retry(String id);

  /// Retry all failed jobs of a specific type
  Future<List<FailedJob>> retryByType(String jobType);

  /// Prune old failed jobs
  Future<int> prune({Duration? olderThan});

  /// Get failed job report
  Future<Map<String, dynamic>> getReport();

  /// Export failed jobs to JSON
  Future<String> exportToJson({int? limit});
}
