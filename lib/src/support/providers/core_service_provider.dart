import 'package:timezone/data/latest.dart' as tz;

import '../../contracts/config/config_contract.dart';
import '../../contracts/container/container_interface.dart';
import '../../contracts/env/env_interface.dart';
import '../../contracts/events/event_system_interface.dart';
import '../../contracts/lang/lang_provider.dart';
import '../../contracts/provider/service_provider.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/core.dart';
import '../../core/http/middleware/middleware_pipeline.dart';
import '../../core/logging/logger.dart';
import '../../core/socket/socket_manager.dart';
import '../../core/storage/storage_manager.dart';
import '../../support/services/url_service.dart';

/// Registers all core services of the Khadem framework,
/// including configuration, environment, logger, router, cache, and events.
class CoreServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    _registerCoreBindings(container);
  }

  /// Register all essential Khadem core services.
  /// Registers all core services of the Khadem framework,
  /// including configuration, environment, logger, router, cache, and events.
  void _registerCoreBindings(ContainerInterface container) {
    container.lazySingleton<Router>((c) => Router());
    container.lazySingleton<CacheManager>((c) => CacheManager());

    container.lazySingleton<EventSystemInterface>((c) => EventSystem());

    container.lazySingleton<EnvInterface>((c) => EnvSystem());

    container.lazySingleton<ConfigInterface>(
      (c) => ConfigSystem(
        configPath: 'config',
        environment:
            c.resolve<EnvInterface>().getOrDefault('APP_ENV', 'development'),
      ),
    );

    container.lazySingleton<Logger>((c) => Logger());

    container.lazySingleton<MiddlewarePipeline>((c) => MiddlewarePipeline());

    container.lazySingleton<StorageManager>((c) => StorageManager());

    container.lazySingleton<LangProvider>((c) => FileLangProvider());

    container.lazySingleton<SocketManager>((c) => SocketManager());

    // URL and Asset Services
    container.lazySingleton<UrlService>((c) {
      final config = c.resolve<ConfigInterface>();
      final appConfig = config.section('app') ?? {};
      final baseUrl = appConfig['url'] ?? 'http://localhost:8080';
      final assetUrl = appConfig['asset_url'];
      final forceHttps = appConfig['force_https'] ?? false;

      final urlService = UrlService(
        baseUrl: baseUrl,
        assetBaseUrl: assetUrl,
        forceHttps: forceHttps,
      );

      // Register named routes from config
      final routes = config.section('routes');
      if (routes != null) {
        for (final entry in routes.entries) {
          final routeName = entry.key;
          final routePath = entry.value as String;
          urlService.registerRoute(routeName, routePath);
        }
      }

      return urlService;
    });

    container.lazySingleton<AssetService>((c) {
      final urlService = c.resolve<UrlService>();
      final storageManager = c.resolve<StorageManager>();
      return AssetService(urlService, storageManager);
    });
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

    container
        .resolve<LangProvider>()
        .setLocale(envSystem.getOrDefault('APP_LOCALE', 'en'));
    Lang.use(container.resolve<LangProvider>());

    final logger = container.resolve<Logger>();
    logger.loadFromConfig(config);
    tz.initializeTimeZones();
    logger.info('✅ Core services initialized');
  }
}
