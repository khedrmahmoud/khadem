import 'dart:async';
import '../../../contracts/queue/middleware/queue_job_context.dart';
import '../../../contracts/queue/middleware/queue_middleware_contract.dart';

/// Timeout middleware
class TimeoutMiddleware implements QueueMiddleware {
  final Duration timeout;

  TimeoutMiddleware({required this.timeout});

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    await next().timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Job execution exceeded timeout of $timeout',
        );
      },
    );
  }

  @override
  String get name => 'TimeoutMiddleware';
}
