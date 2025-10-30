import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Timing middleware
class TimingMiddleware implements QueueMiddleware {
  final void Function(String jobName, Duration duration)? onComplete;

  TimingMiddleware({this.onComplete});

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    final startTime = DateTime.now();

    try {
      await next();
    } finally {
      final duration = DateTime.now().difference(startTime);
      context.addMetadata('processingTime', duration);
      onComplete?.call(context.job.displayName, duration);
    }
  }

  @override
  String get name => 'TimingMiddleware';
}
