import '../../contracts/config/config_contract.dart';
import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';
import '../../core/config/config_system.dart';
import '../../core/logging/logger.dart';
import '../../core/queue/queue_manager.dart';

/// Registers the [QueueManager] which is responsible for initializing and
/// managing the queue system.
///
/// The [QueueManager] is initialized with the configuration from the
/// [ConfigSystem] and is registered as a singleton.
class QueueServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    container.lazySingleton<QueueManager>(
      (c) => QueueManager(c.resolve<ConfigInterface>()),
    );
  }

  @override

  /// Initializes the [QueueManager] by calling its [init] method.
  Future<void> boot(ContainerInterface container) async {
    final queue = container.resolve<QueueManager>();
    final config = container.resolve<ConfigInterface>();
    queue.loadFromConfig();
    container
        .resolve<Logger>()
        .info('✅ Queue system initialized (${queue.defaultDriverName})');
    if (config.get<bool?>('queue.auto_start') ?? false) {
      queue.startWorker(
        maxJobs: config.get<int?>('queue.max_jobs'),
        delay: Duration(seconds: config.get<int?>('queue.delay') ?? 1),
        timeout: config.get<int?>('queue.timeout') == null
            ? null
            : Duration(seconds: config.get<int?>('queue.timeout')!),
        runInBackground: config.get<bool?>('queue.run_in_background') ?? false,
        onError: (error, stack) {
          container.resolve<Logger>().error(error, stackTrace: stack);
        },
      );
    }
  }
}
