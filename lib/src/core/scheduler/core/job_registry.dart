import '../../../contracts/scheduler/job_definition.dart';
import '../../../contracts/scheduler/scheduled_job.dart';
import '../../../support/scheduled_tasks/ping_job.dart';
import '../../../support/scheduled_tasks/ttl_file_cleaner_task.dart';

/// Registry for managing scheduled jobs
///
/// This class provides a centralized way to register and resolve
/// scheduled jobs by name. It supports both built-in jobs and
/// user-defined custom jobs.
class SchedulerJobRegistry {
  /// Internal storage for registered jobs
  static final Map<String, JobDefinition> _jobs = {};

  /// Register all built-in scheduled jobs
  ///
  /// This method should be called during application bootstrap
  /// to register the default jobs that come with the framework.
  static void registerAll() {
    register(
      JobDefinition(
        name: 'ping',
        factory: (config) => PingJob(),
      ),
    );

    register(
      JobDefinition(
        name: 'ttl_cleaner',
        factory: (config) => TTLFileCleanerJob(
          cachePath: (config['cachePath'] ?? 'storage/cache') as String,
        ),
      ),
    );
  }

  /// Register a new job definition
  ///
  /// [job] The job definition to register
  /// Throws [ArgumentError] if a job with the same name already exists
  static void register(JobDefinition job) {
    if (_jobs.containsKey(job.name)) {
      throw ArgumentError('Job "${job.name}" is already registered');
    }
    _jobs[job.name] = job;
  }

  /// Resolve a job by name and configuration
  ///
  /// [name] The name of the job to resolve
  /// [config] Configuration parameters for the job
  /// Returns the resolved job instance or null if not found
  static ScheduledJob? resolve(String name, Map<String, dynamic> config) {
    final definition = _jobs[name];
    if (definition == null) {
      return null;
    }
    return definition.factory(config);
  }

  /// Get a list of all registered job names
  static List<String> get registeredNames => _jobs.keys.toList();

  /// Check if a job is registered
  ///
  /// [name] The name of the job to check
  /// Returns true if the job is registered, false otherwise
  static bool isRegistered(String name) => _jobs.containsKey(name);

  /// Get the number of registered jobs
  static int get count => _jobs.length;

  /// Unregister a job by name
  ///
  /// [name] The name of the job to unregister
  /// Returns true if the job was unregistered, false if it wasn't found
  static bool unregister(String name) => _jobs.remove(name) != null;

  /// Clear all registered jobs
  static void clear() => _jobs.clear();
}
