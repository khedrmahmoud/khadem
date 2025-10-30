import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Conditional middleware - only run if condition is met
class ConditionalMiddleware implements QueueMiddleware {
  final bool Function(QueueJobContext context) condition;
  final QueueMiddleware middleware;

  ConditionalMiddleware({
    required this.condition,
    required this.middleware,
  });

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    if (condition(context)) {
      await middleware.handle(context, next);
    } else {
      await next();
    }
  }

  @override
  String get name => 'ConditionalMiddleware(${middleware.name})';
}
