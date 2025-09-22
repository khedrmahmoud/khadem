import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';

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

  /// Get the number of pending jobs
  int get pendingJobsCount => _jobs.length;

  /// Clear all pending jobs
  void clear() {
    _jobs.clear();
  }
}

class _DelayedJob {
  final QueueJob job;
  final DateTime scheduledAt;

  _DelayedJob(this.job, this.scheduledAt);
}
