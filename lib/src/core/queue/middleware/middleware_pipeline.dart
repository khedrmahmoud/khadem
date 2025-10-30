import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Middleware pipeline for queue jobs
class QueueMiddlewarePipeline {
  final List<QueueMiddleware> _middleware = [];

  /// Add middleware to the pipeline
  void add(QueueMiddleware middleware) {
    _middleware.add(middleware);
  }

  /// Add middleware at a specific position
  void addAt(int index, QueueMiddleware middleware) {
    _middleware.insert(index, middleware);
  }

  /// Remove middleware
  void remove(QueueMiddleware middleware) {
    _middleware.remove(middleware);
  }

  /// Clear all middleware
  void clear() {
    _middleware.clear();
  }

  /// Execute the pipeline
  Future<void> execute(QueueJobContext context) async {
    if (_middleware.isEmpty) {
      // No middleware, just execute the job
      await _executeJob(context);
      return;
    }

    // Build the middleware chain
    int index = 0;

    Future<void> next() async {
      if (index >= _middleware.length) {
        // End of middleware chain, execute the job
        await _executeJob(context);
        return;
      }

      final middleware = _middleware[index++];
      await middleware.handle(context, next);
    }

    await next();
  }

  Future<void> _executeJob(QueueJobContext context) async {
    try {
      await context.job.handle();
      context.result = true; // Job completed successfully
    } catch (e, stack) {
      context.error = e;
      context.stackTrace = stack;
      rethrow;
    }
  }

  /// Get middleware count
  int get count => _middleware.length;

  /// Get all middleware
  List<QueueMiddleware> get middleware => List.unmodifiable(_middleware);
}
