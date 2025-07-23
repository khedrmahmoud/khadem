import '../../contracts/config/config_contract.dart';
import '../../contracts/env/env_interface.dart';
import '../../contracts/container/container_interface.dart';
import '../../contracts/events/event_system_interface.dart';
import '../../contracts/provider/service_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../core/core.dart';
import '../../core/http/middleware/middleware_pipeline.dart';
import '../../core/storage/storage_manager.dart';
import '../../infrastructure/cache/cache_manager.dart';
import '../../infrastructure/logging/logger.dart';

/// Registers all core services of the Khadem framework,
/// including configuration, environment, logger, router, cache, and events.
class CoreServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    _registerCoreBindings(container);
  }

  /// Register all essential Khadem core services.
  void _registerCoreBindings(ContainerInterface container) {
    container.lazySingleton<Router>((c) => Router());
    container.lazySingleton<CacheManager>((c) => CacheManager());

    container.lazySingleton<EventSystemInterface>((c) => EventSystem());

    container.lazySingleton<EnvInterface>((c) => EnvSystem());

    container.lazySingleton<ConfigInterface>((c) => ConfigSystem(
          configPath: 'config',
          environment:
              c.resolve<EnvInterface>().getOrDefault('APP_ENV', 'development'),
        ));

    container.lazySingleton<Logger>((c) => Logger());

    container.lazySingleton<MiddlewarePipeline>((c) => MiddlewarePipeline());

    container.lazySingleton<StorageManager>((c) => StorageManager());
  }

  /// Boot logic for core services such as loading `.env` and logging startup.
  @override
  Future<void> boot(ContainerInterface container) async {
    final envSystem = container.resolve<EnvInterface>();
    envSystem.loadFromFile('.env');

    final config = container.resolve<ConfigInterface>() as ConfigSystem;
    config.setEnvironment(envSystem.getOrDefault('APP_ENV', 'development'));

// Load cache manager
    final cacheManager = container.resolve<CacheManager>();
    cacheManager.loadFromConfig(config);

// Load storage manager
    final storageManager = container.resolve<StorageManager>();
    storageManager.fromConfig(config.section('storage') ?? {});

    Lang.setRequestLocale(envSystem.getOrDefault('APP_LOCALE', 'en'));

    final logger = container.resolve<Logger>();
    logger.loadFromConfig(config);
    tz.initializeTimeZones();
    logger.info('✅ Core services initialized');
  }
}
