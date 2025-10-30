import 'dart:async';
import 'queue_job_context.dart';

/// Next function type for middleware chain
typedef Next = Future<void> Function();

/// Middleware interface for queue jobs
abstract class QueueMiddleware {
  /// Handle the job context
  /// Call next() to continue to the next middleware or job execution
  Future<void> handle(QueueJobContext context, Next next);

  /// Get middleware name for debugging
  String get name => runtimeType.toString();
}
