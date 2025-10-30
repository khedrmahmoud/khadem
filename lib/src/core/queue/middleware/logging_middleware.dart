import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Logging middleware
class QueueLoggingMiddleware implements QueueMiddleware {
  final void Function(String message)? logger;

  QueueLoggingMiddleware({this.logger});

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    final log = logger ?? print;

    log('📋 [Queue] Starting job: ${context.job.displayName}');

    try {
      await next();

      log('✅ [Queue] Job completed: ${context.job.displayName} (${context.elapsed.inMilliseconds}ms)');
    } catch (e) {
      log('❌ [Queue] Job failed: ${context.job.displayName} - $e');
      rethrow;
    }
  }

  @override
  String get name => 'LoggingMiddleware';
}
