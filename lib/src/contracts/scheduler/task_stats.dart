/// Statistics for a scheduled task
class TaskStats {
  /// The name of the task
  final String name;

  /// When the task was last executed
  final DateTime? lastRun;

  /// When the task is next scheduled to run
  final DateTime? nextRun;

  /// Number of times the task has run successfully
  final int successCount;

  /// Number of times the task has failed
  final int failureCount;

  /// Average execution time in milliseconds
  final double averageExecutionTime;

  /// Current status of the task
  final TaskStatus status;

  /// Create a new TaskStats instance
  const TaskStats({
    required this.name,
    this.lastRun,
    this.nextRun,
    this.successCount = 0,
    this.failureCount = 0,
    this.averageExecutionTime = 0.0,
    this.status = TaskStatus.idle,
  });

  /// Create a copy of this TaskStats with some properties changed
  TaskStats copyWith({
    String? name,
    DateTime? lastRun,
    DateTime? nextRun,
    int? successCount,
    int? failureCount,
    double? averageExecutionTime,
    TaskStatus? status,
  }) {
    return TaskStats(
      name: name ?? this.name,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun ?? this.nextRun,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      averageExecutionTime: averageExecutionTime ?? this.averageExecutionTime,
      status: status ?? this.status,
    );
  }
}

/// Status of a scheduled task
enum TaskStatus {
  /// Task is idle (not running)
  idle,

  /// Task is currently running
  running,

  /// Task is paused
  paused,

  /// Task is stopped
  stopped,

  /// Task has failed
  failed,
}
