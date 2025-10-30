import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Before/After hook middleware
class HookMiddleware implements QueueMiddleware {
  final Future<void> Function(QueueJobContext context)? before;
  final Future<void> Function(QueueJobContext context)? after;

  HookMiddleware({this.before, this.after});

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    if (before != null) {
      await before!(context);
    }

    try {
      await next();
    } finally {
      if (after != null) {
        await after!(context);
      }
    }
  }

  @override
  String get name => 'HookMiddleware';
}
