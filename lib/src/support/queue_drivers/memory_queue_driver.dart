import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';

class MemoryQueueDriver implements QueueDriver {
  final List<_DelayedJob> _jobs = [];

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final scheduledAt = DateTime.now().add(delay ?? Duration.zero);
    _jobs.add(_DelayedJob(job, scheduledAt));
  }

  @override
  Future<void> process() async {
    final now = DateTime.now();
    final ready = _jobs.where((j) => j.scheduledAt.isBefore(now)).toList();
    for (final job in ready) {
      await job.job.handle();
      _jobs.remove(job);
    }
  }
}

class _DelayedJob {
  final QueueJob job;
  final DateTime scheduledAt;

  _DelayedJob(this.job, this.scheduledAt);
}
