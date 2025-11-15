import '../../application/khadem.dart';
import '../../contracts/scheduler/job_definition.dart';
import 'core/job_registry.dart';
import 'core/scheduled_task.dart';
import 'scheduler.dart';

/// Global scheduler instance
final scheduler = SchedulerEngine();

/// Bootstrap function to initialize and start the scheduler system
///
/// This function should be called during application startup to:
/// - Register built-in jobs
/// - Register custom jobs provided by the user
/// - Load and start tasks from configuration
///
/// [tasks] Additional tasks to add beyond configuration
/// [configJobs] Custom job definitions to register
void startSchedulers({
  List<ScheduledTask> tasks = const [],
  List<JobDefinition> configJobs = const [],
}) {
  final logger = Khadem.logger;

  try {
    // Register built-in jobs
    SchedulerJobRegistry.registerAll();

    // Register custom jobs
    for (final job in configJobs) {
      SchedulerJobRegistry.register(job);
    }

    // Add provided tasks
    for (var task in tasks) {
      scheduler.add(task);
    }

    // Load tasks from configuration
    final config = Khadem.config.section('scheduler') ?? {};
    final configTasks = config['tasks'] as List<dynamic>? ?? [];

    for (var configItem in configTasks) {
      try {
        final task =
            ScheduledTask.fromConfig(configItem as Map<String, dynamic>);
        scheduler.add(task);
      } catch (e) {
        logger.error('❌ Failed to load task from config: $e');
        // Continue with other tasks even if one fails
      }
    }

    logger.info('✅ Scheduler system initialized successfully');
  } catch (e, stackTrace) {
    logger.error('❌ Failed to initialize scheduler system: $e');
    logger.error('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Shutdown function to gracefully stop all scheduler activities
///
/// This function should be called during application shutdown
void stopSchedulers() {
  final logger = Khadem.logger;
  logger.info('🛑 Shutting down scheduler system...');

  try {
    scheduler.stopAll();
    logger.info('✅ All scheduler tasks stopped');
  } catch (e) {
    logger.error('❌ Error during scheduler shutdown: $e');
  }
}
