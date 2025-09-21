import '../../core/scheduler/core/scheduled_task.dart';
import 'task_stats.dart';

/// Contract for the Scheduler Engine
abstract class SchedulerEngineContract {
  /// Add a new scheduled task
  void add(ScheduledTask task);

  /// Stop a specific task by name
  void stop(String name);

  /// Stop all running tasks
  void stopAll();

  /// Check if a task is currently running
  bool isRunning(String name);

  /// Get a list of active task names
  List<String> activeTasks();

  /// Pause a specific task
  void pause(String name);

  /// Resume a paused task
  void resume(String name);

  /// Get task statistics
  Map<String, TaskStats> getStats();
}
