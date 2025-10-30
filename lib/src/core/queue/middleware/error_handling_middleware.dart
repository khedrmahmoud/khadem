import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Error handling middleware
class ErrorHandlingMiddleware implements QueueMiddleware {
  final void Function(dynamic job, dynamic error, StackTrace stack)? onError;
  final bool rethrowErrors;

  ErrorHandlingMiddleware({
    this.onError,
    this.rethrowErrors = true,
  });

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    try {
      await next();
    } catch (e, stack) {
      onError?.call(context.job, e, stack);

      if (rethrowErrors) {
        rethrow;
      }
    }
  }

  @override
  String get name => 'ErrorHandlingMiddleware';
}
