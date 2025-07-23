/// Represents a job that can be scheduled for execution at a specific time or interval.
///
/// Implement this abstract class to define your own scheduled jobs.
///
/// Example:
/// ```dart
/// class CleanupJob extends ScheduledJob {
///   @override
///   String get name => 'cleanup_job';
///
///   @override
///   Future<void> execute() async {
///     // your logic here
///   }
/// }
/// ```
abstract class ScheduledJob {
  /// Unique name of the job (used for identification and control).
  String get name;

  /// Main logic that should be executed when the job runs.
  Future<void> execute();
}
