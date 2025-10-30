import '../../../contracts/queue/queue_job.dart';
import 'job_priority.dart';
import 'prioritized_job.dart';
import 'priority_queue.dart';

/// In-memory priority queue driver
class InMemoryPriorityQueueDriver {
  final PriorityQueue<PrioritizedJob> _queue = PriorityQueue<PrioritizedJob>();
  final Map<String, PrioritizedJob> _jobsById = {};
  int _idCounter = 0;

  /// Push a job with priority
  Future<void> push(
    QueueJob job, {
    JobPriority priority = JobPriority.normal,
    Duration? delay,
  }) async {
    final id = 'job_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

    final prioritizedJob = PrioritizedJob(
      job: job,
      priority: priority,
      id: id,
    );

    if (delay != null && delay > Duration.zero) {
      // Schedule delayed job
      Future.delayed(delay, () {
        _queue.add(prioritizedJob);
        _jobsById[id] = prioritizedJob;
      });
    } else {
      _queue.add(prioritizedJob);
      _jobsById[id] = prioritizedJob;
    }
  }

  /// Process next highest priority job
  Future<void> process() async {
    final prioritizedJob = _queue.removeFirst();
    if (prioritizedJob == null) return;

    _jobsById.remove(prioritizedJob.id);

    try {
      await prioritizedJob.job.handle();
    } catch (e) {
      // Error handling would go here
      rethrow;
    }
  }

  /// Get queue statistics by priority
  Map<String, dynamic> getStatsByPriority() {
    final stats = <String, int>{};

    for (final priority in JobPriority.values) {
      stats[priority.name] = 0;
    }

    for (final job in _queue.toList()) {
      stats[job.priority.name] = (stats[job.priority.name] ?? 0) + 1;
    }

    return {
      'total': _queue.length,
      'byPriority': stats,
      'nextJob': _queue.peek()?.toJson(),
    };
  }

  /// Get all jobs sorted by priority
  List<PrioritizedJob> getAllJobs() => _queue.toList();

  /// Get job by ID
  PrioritizedJob? getJobById(String id) => _jobsById[id];

  /// Remove job by ID
  bool removeJobById(String id) {
    final job = _jobsById[id];
    if (job == null) return false;

    _jobsById.remove(id);
    return _queue.remove(job);
  }

  /// Clear all jobs
  void clear() {
    _queue.clear();
    _jobsById.clear();
  }

  /// Get pending job count
  int get pendingJobs => _queue.length;

  /// Check if empty
  bool get isEmpty => _queue.isEmpty;
}
