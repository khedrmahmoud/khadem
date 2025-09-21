import 'scheduled_job.dart';

/// A factory wrapper that defines how to create scheduled job instances from config.
///
/// Useful when loading jobs dynamically from configuration files or external sources.
///
/// Example:
/// ```dart
/// JobDefinition(
///   name: 'cleanup_job',
///   factory: (config) => CleanupJob(),
/// )
/// ```
class JobDefinition {
  /// Unique identifier of the job definition (usually the job type).
  final String name;

  /// A function that returns a [ScheduledJob] instance using provided config.
  final ScheduledJob Function(Map<String, dynamic> config) factory;

  JobDefinition({
    required this.name,
    required this.factory,
  });
}
