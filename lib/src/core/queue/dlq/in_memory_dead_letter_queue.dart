import '../../../contracts/queue/dlq/dead_letter_queue_contract.dart';
import '../../../contracts/queue/dlq/failed_job.dart';

/// In-memory implementation of Dead Letter Queue
class InMemoryDeadLetterQueue implements DeadLetterQueue {
  final Map<String, FailedJob> _jobs = {};

  @override
  Future<void> store(FailedJob job) async {
    _jobs[job.id] = job;
  }

  @override
  Future<FailedJob?> get(String id) async {
    return _jobs[id];
  }

  @override
  Future<List<FailedJob>> getAll({int? limit, int? offset}) async {
    var jobs = _jobs.values.toList()
      ..sort((a, b) => b.failedAt.compareTo(a.failedAt));

    if (offset != null) {
      jobs = jobs.skip(offset).toList();
    }

    if (limit != null) {
      jobs = jobs.take(limit).toList();
    }

    return jobs;
  }

  @override
  Future<List<FailedJob>> getByType(String jobType, {int? limit}) async {
    var jobs = _jobs.values.where((job) => job.jobType == jobType).toList()
      ..sort((a, b) => b.failedAt.compareTo(a.failedAt));

    if (limit != null) {
      jobs = jobs.take(limit).toList();
    }

    return jobs;
  }

  @override
  Future<List<FailedJob>> getByDateRange(DateTime start, DateTime end) async {
    return _jobs.values
        .where(
          (job) => job.failedAt.isAfter(start) && job.failedAt.isBefore(end),
        )
        .toList()
      ..sort((a, b) => b.failedAt.compareTo(a.failedAt));
  }

  @override
  Future<void> remove(String id) async {
    _jobs.remove(id);
  }

  @override
  Future<void> clear() async {
    _jobs.clear();
  }

  @override
  Future<int> count() async {
    return _jobs.length;
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final typeStats = <String, int>{};
    final errorStats = <String, int>{};

    for (final job in _jobs.values) {
      typeStats[job.jobType] = (typeStats[job.jobType] ?? 0) + 1;
      errorStats[job.error] = (errorStats[job.error] ?? 0) + 1;
    }

    return {
      'total': _jobs.length,
      'byType': typeStats,
      'byError': errorStats,
      'oldestFailure': _jobs.isEmpty
          ? null
          : _jobs.values
              .reduce((a, b) => a.failedAt.isBefore(b.failedAt) ? a : b)
              .failedAt
              .toIso8601String(),
      'newestFailure': _jobs.isEmpty
          ? null
          : _jobs.values
              .reduce((a, b) => a.failedAt.isAfter(b.failedAt) ? a : b)
              .failedAt
              .toIso8601String(),
    };
  }
}
