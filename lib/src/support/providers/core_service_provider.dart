// ignore_for_file: deprecated_member_use_from_same_package
import 'package:khadem/config.dart';
import 'package:khadem/contracts.dart';
import 'package:khadem/events.dart';
import 'package:khadem/http.dart' show MiddlewarePipeline;
import 'package:khadem/khadem.dart';
import 'package:khadem/lang.dart';
import 'package:khadem/logging.dart';
import 'package:khadem/routing.dart' show Router;
import 'package:khadem/socket.dart' show SocketManager;
import 'package:khadem/storage.dart' show StorageManager;
import 'package:khadem/support.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../core/exception/exception_handler.dart';

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
    _registerBaseServices(container);
    _registerStorageServices(container);
    _registerUrlServices(container);
    _registerLocalizationServices(container);
  }

  void _registerBaseServices(ContainerInterface container) {
    container.lazySingleton<ExceptionHandlerContract>(
      (c) => ExceptionHandler(),
    );
    container.lazySingleton<Router>((c) => Router());
    container.lazySingleton<EventSystemInterface>((c) => EventSystem());
    container.lazySingleton<Dispatcher>((c) => EventDispatcher(c));
    container.lazySingleton<EnvInterface>((c) => EnvSystem());
    container.lazySingleton<ConfigInterface>(
      (c) => ConfigSystem(
        configPath: 'config',
        environment: c.resolve<EnvInterface>().getOrDefault(
          'APP_ENV',
          'development',
        ),
      ),
    );
    container.lazySingleton<Logger>((c) => Logger());
    container.lazySingleton<MiddlewarePipeline>((c) => MiddlewarePipeline());
    container.lazySingleton<SocketManager>((c) => SocketManager());
  }

  void _registerStorageServices(ContainerInterface container) {
    container.lazySingleton<StorageManager>((c) => StorageManager());
  }

  void _registerLocalizationServices(ContainerInterface container) {
    container.lazySingleton<LangProvider>((c) => FileLangProvider());
  }

  void _registerUrlServices(ContainerInterface container) {
    container.lazySingleton<UrlService>((c) {
      final config = c.resolve<ConfigInterface>();
      final env = c.resolve<EnvInterface>();
      final appConfig = config.section('app') ?? {};

      final assetUrl =
          appConfig['asset_url'] as String? ?? env.get('ASSET_URL');
      final forceHttps =
          appConfig['force_https'] as bool? ?? env.getBool('FORCE_HTTPS');

      final urlService = UrlService(
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

    // Configure exception handling verbosity based on environment.
    final isDebug = envSystem.getBool(
      'APP_DEBUG',
      defaultValue: Khadem.isDevelopment, // Default to true in development mode
    );
    final exceptionHandler =
        container.resolve<ExceptionHandlerContract>() as ExceptionHandler;
    exceptionHandler.configure(
      showDetailedErrors: isDebug,
      includeStackTracesInResponse: isDebug,
    );

    // Load storage manager
    final storageManager = container.resolve<StorageManager>();
    storageManager.fromConfig(config.section('storage') ?? {});

    Lang.use(container.resolve<LangProvider>());
    Lang.setGlobalLocale(envSystem.getOrDefault('APP_LOCALE', 'en'));

    final logger = container.resolve<Logger>();
    logger.loadFromConfig(config);
    tz.initializeTimeZones();
    logger.info('✅ Core services initialized');
  }
}
