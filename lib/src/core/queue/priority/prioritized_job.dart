import '../../../contracts/queue/queue_job.dart';
import 'job_priority.dart';

/// Represents a job with priority and metadata
class PrioritizedJob implements Comparable<PrioritizedJob> {
  final QueueJob job;
  final JobPriority priority;
  final DateTime queuedAt;
  final String id;

  PrioritizedJob({
    required this.job,
    required this.priority,
    required this.id,
  }) : queuedAt = DateTime.now();

  @override
  int compareTo(PrioritizedJob other) {
    // Higher priority comes first
    final priorityComparison = other.priority.value.compareTo(priority.value);
    if (priorityComparison != 0) {
      return priorityComparison;
    }

    // If same priority, older jobs come first (FIFO)
    return queuedAt.compareTo(other.queuedAt);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'priority': priority.name,
        'queuedAt': queuedAt.toIso8601String(),
        'jobType': job.runtimeType.toString(),
      };

  @override
  String toString() {
    return 'PrioritizedJob{id: $id, priority: ${priority.name}, queuedAt: $queuedAt}';
  }
}

/// Extension to add priority to jobs
extension PriorityQueueJob on QueueJob {
  /// Get job priority (default: normal)
  JobPriority get priority => JobPriority.normal;
}
