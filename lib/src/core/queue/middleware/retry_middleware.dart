import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Retry middleware
class RetryMiddleware implements QueueMiddleware {
  final int maxAttempts;
  final Duration delay;
  final bool Function(dynamic error)? shouldRetry;

  RetryMiddleware({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
    this.shouldRetry,
  });

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    int attempt = 0;

    while (attempt < maxAttempts) {
      try {
        await next();
        return; // Success, exit
      } catch (e) {
        attempt++;
        context.addMetadata('attempts', attempt);

        // Check if we should retry
        if (attempt >= maxAttempts) {
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry!(e)) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay * attempt);
      }
    }
  }

  @override
  String get name => 'RetryMiddleware';
}
