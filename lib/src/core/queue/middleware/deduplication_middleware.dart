import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Prevents duplicate job execution within time window
class DeduplicationMiddleware implements QueueMiddleware {
  final Duration window;
  final int maxEntries;
  final Map<String, DateTime> _processedJobs = {};

  DeduplicationMiddleware({required this.window, this.maxEntries = 10000});

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    final jobId = context.metadata['job_id'] as String?;
    if (jobId == null) {
      await next();
      return;
    }

    final now = DateTime.now();
    final lastProcessed = _processedJobs[jobId];

    if (lastProcessed != null && now.difference(lastProcessed) < window) {
      // Skip duplicate job
      return;
    }

    _cleanExpiredEntries(now);
    _ensureCapacity(jobId);
    _processedJobs[jobId] = now;

    await next();
  }

  void _cleanExpiredEntries(DateTime now) {
    _processedJobs.removeWhere((_, value) => now.difference(value) > window);
  }

  void _ensureCapacity(String incomingJobId) {
    if (_processedJobs.length < maxEntries ||
        _processedJobs.containsKey(incomingJobId)) {
      return;
    }

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _processedJobs.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _processedJobs.remove(oldestKey);
    }
  }

  @override
  String get name => 'DeduplicationMiddleware';
}
