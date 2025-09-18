import '../../core/scheduler/core/scheduled_task.dart';

/// Scheduler interface for managing and executing scheduled tasks.
///
/// Allows scheduling tasks, stopping them, and checking their status.
/// Intended to be implemented by classes like CronScheduler, IntervalScheduler, etc.
abstract class Scheduler {
  /// Adds a new scheduled [task] to the scheduler.
  void schedule(ScheduledTask task);

  /// Stops a running task by its unique [name].
  void stop(String name);

  /// Stops all running scheduled tasks.
  void stopAll();

  /// Returns the current status of all scheduled tasks.
  ///
  /// Example output:
  /// ```json
  /// [
  ///   { "name": "cleanup_job", "running": true, "nextRun": "2025-07-18T12:00:00Z" },
  ///   { "name": "daily_report", "running": false }
  /// ]
  /// ```
  List<Map<String, dynamic>> status();
}
