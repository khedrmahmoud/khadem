import 'failed_job.dart';

/// Dead Letter Queue interface for handling permanently failed jobs
abstract interface class DeadLetterQueue {
  /// Store a failed job in the DLQ
  Future<void> store(FailedJob job);

  /// Retrieve a failed job by ID
  Future<FailedJob?> get(String id);

  /// Get all failed jobs
  Future<List<FailedJob>> getAll({int? limit, int? offset});

  /// Get failed jobs filtered by type
  Future<List<FailedJob>> getByType(String jobType, {int? limit});

  /// Get failed jobs within a date range
  Future<List<FailedJob>> getByDateRange(DateTime start, DateTime end);

  /// Remove a failed job from the DLQ
  Future<void> remove(String id);

  /// Clear all failed jobs
  Future<void> clear();

  /// Get the total count of failed jobs
  Future<int> count();

  /// Get failed job statistics
  Future<Map<String, dynamic>> getStats();
}
