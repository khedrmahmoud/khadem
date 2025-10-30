import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Prevents duplicate job execution within time window
class DeduplicationMiddleware implements QueueMiddleware {
  final Duration window;
  final Map<String, DateTime> _processedJobs = {};

  DeduplicationMiddleware({required this.window});

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

    _processedJobs[jobId] = now;

    // Clean old entries
    _processedJobs.removeWhere(
      (key, value) => now.difference(value) > window,
    );

    await next();
  }

  @override
  String get name => 'DeduplicationMiddleware';
}
