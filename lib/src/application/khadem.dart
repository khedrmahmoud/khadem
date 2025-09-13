import 'package:khadem/khadem_dart.dart';
import 'package:khadem/src/contracts/cache/cache_interfaces.dart' show ICacheManager;
import 'package:khadem/src/support/providers/cache_service_provider.dart';


/// Central access point for all Khadem framework services and utilities.
class Khadem {
  Khadem._();

  // ========= 🔧 Container & Provider System =========

  static ContainerInterface? _customContainer;

  /// Returns the current IoC container (default or custom).
  static ContainerInterface get container =>
      _customContainer ?? ContainerProvider.instance;

  /// Returns the service provider manager.
  static final ServiceProviderManager _providerManager =
      ServiceProviderManager(container);

  static ServiceProviderManager get providers => _providerManager;

  // ========= ⚙️ Core Bootstrapping =========

  /// Registers application service providers (user-managed, like Laravel's Kernel).
  static Future<void> registerApplicationServices(List<ServiceProvider> serviceProviders) async {
    register(serviceProviders);
  }

  /// Lightweight boot (ideal for master isolate).
  static Future<void> boot() async {
    await providers.bootAll();
  }

  /// Register service providers.
  static void register(List<ServiceProvider> serviceProviders) {
    providers.registerAll(serviceProviders);
  }

  /// Inject external container (useful for testing).
  static Future<ContainerInterface> use(ContainerInterface container) async {
    _customContainer = container;
    return _customContainer!;
  }

  /// Register configurations from a registry map.
  static void loadConfigs(Map<String, Map<String, dynamic>> configs) {
    config.loadFromRegistry(configs);
  }

  // ========= 🧠 Common Services =========

  static Logger get logger => container.resolve<Logger>();
  static ICacheManager get cache => container.resolve<ICacheManager>();
  static EnvInterface get env => container.resolve<EnvInterface>();
  static ConfigInterface get config => container.resolve<ConfigInterface>();

  static MiddlewarePipeline get middleware =>
      container.resolve<MiddlewarePipeline>();
  static DatabaseManager get db => container.resolve<DatabaseManager>();
  static Migrator get migrator => container.resolve<Migrator>();
  static SeederManager get seeder => container.resolve<SeederManager>();
  static QueueManager get queue => container.resolve<QueueManager>();
  static EventSystemInterface get eventBus =>
      container.resolve<EventSystemInterface>();
  static SocketManager get socket => container.resolve<SocketManager>();
  static StorageManager get storage => container.resolve<StorageManager>();

  // URL and Asset Services
  static UrlService get urlService => container.resolve<UrlService>();
  static AssetService get assetService => container.resolve<AssetService>();

 

  // ========= 📅 Scheduler & View System =========

  /// Returns the scheduler engine for managing tasks.
  static SchedulerEngine get scheduler => SchedulerEngine();

  /// Returns the view renderer for template rendering.
  static ViewRenderer get view => ViewRenderer.instance;

  // ========= 🛠️ Miscellaneous Helpers & Utilities ========

  /// Framework version.
  static String get version => '1.0.0';

  /// Checks if the framework is fully booted.
  static bool get isBooted => providers.isBooted;

  /// Checks if the application is running in production mode.
  static bool get isProduction =>
      env.getOrDefault('APP_ENV', 'production') == 'production';

  /// Checks if the application is running in development mode.
  static bool get isDevelopment =>
      env.getOrDefault('APP_ENV', 'production') == 'development';

  /// Shuts down all services (e.g., stops schedulers, closes DB connections).
  static Future<void> shutdown() async {
    scheduler.stopAll();
    await db.close();
    // Add more cleanup as needed
  }
}
