import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';

class SyncQueueDriver implements QueueDriver {
  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    await job.handle();
  }

  @override
  Future<void> process() async {
    // nothing
  }
}
