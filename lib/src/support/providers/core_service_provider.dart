import 'package:khadem/khadem.dart'
    show
        AssetService,
        ConfigInterface,
        ConfigSystem,
        ContainerInterface,
        EnvInterface,
        EnvSystem,
        EventSystem,
        EventSystemInterface,
        FileLangProvider,
        Lang,
        LangProvider,
        Logger,
        MiddlewarePipeline,
        ServiceProvider,
        SocketManager,
        StorageManager,
        UrlService,
        Router;
import 'package:timezone/data/latest.dart' as tz;

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
