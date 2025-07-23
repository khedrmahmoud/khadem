import '../../../contracts/scheduler/job_definition.dart';
import '../../../contracts/scheduler/scheduled_job.dart';
import '../../../support/scheduled_tasks/ping_job.dart';
import '../../../support/scheduled_tasks/ttl_file_cleaner_task.dart';

class SchedulerJobRegistry {
  static final Map<String, JobDefinition> _jobs = {};

  static void registerAll() {
    register(JobDefinition(
      name: 'ping',
      factory: (config) => PingJob(),
    ));

    register(JobDefinition(
      name: 'ttl_cleaner',
      factory: (config) => TTLFileCleanerJob(
        cachePath: config['cachePath'] ?? 'storage/cache',
      ),
    ));
  }

  static void register(JobDefinition job) {
    _jobs[job.name] = job;
  }

  static ScheduledJob? resolve(String name, Map<String, dynamic> config) {
    return _jobs[name]?.factory(config);
  }

  static List<String> get registeredNames => _jobs.keys.toList();
}
