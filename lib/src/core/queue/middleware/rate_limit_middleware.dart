import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Rate limiting middleware
class RateLimitMiddleware implements QueueMiddleware {
  final int maxJobsPerSecond;
  final List<DateTime> _jobTimestamps = [];

  RateLimitMiddleware({required this.maxJobsPerSecond});

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    // Remove timestamps older than 1 second
    final now = DateTime.now();
    _jobTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inSeconds >= 1,
    );

    // Check if we've exceeded the rate limit
    if (_jobTimestamps.length >= maxJobsPerSecond) {
      // Wait until we can process
      final oldestTimestamp = _jobTimestamps.first;
      final waitTime =
          const Duration(seconds: 1) - now.difference(oldestTimestamp);

      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
      }
    }

    _jobTimestamps.add(now);
    await next();
  }

  @override
  String get name => 'RateLimitMiddleware';
}
