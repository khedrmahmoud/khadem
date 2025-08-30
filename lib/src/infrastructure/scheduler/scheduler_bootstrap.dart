import '../../application/khadem.dart';
import '../../contracts/scheduler/job_definition.dart';
import 'core/job_registry.dart';
import 'core/scheduled_task.dart';
import 'scheduler.dart';

final scheduler = SchedulerEngine();

void startSchedulers(
    {List<ScheduledTask> tasks = const [],
    List<JobDefinition> configJobs = const [],}) {
  final config = Khadem.config.section('scheduler') ?? {};

  for (var task in tasks) {
    scheduler.add(task);
  }
  SchedulerJobRegistry.registerAll();
  for (final job in configJobs) {
    SchedulerJobRegistry.register(job);
  }

  for (var config in (config['tasks'] ?? []) as List<dynamic>) {
    final task = ScheduledTask.fromConfig(config as Map<String, dynamic>);
    scheduler.add(task);
  }
}
