import 'package:khadem/khadem_dart.dart';
import '../core/queue/queue.dart' as LaravelQueue;
import '../contracts/queue/queue_job.dart' as QueueContract;
import '../core/http/session.dart';

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

  /// Registers core service providers (only essential framework services).
  static Future<void> registerCoreServices() async {
    register([
      CoreServiceProvider(),
    ]);
  }

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
  static CacheManager get cache => container.resolve<CacheManager>();
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

  // ========= 📋 Laravel-style Queue Helpers =========

  /// Dispatch a job to the queue (Laravel-style)
  static Future<void> dispatch(QueueContract.QueueJob job, {Duration? delay, String? onQueue}) async {
    await LaravelQueue.Queue.dispatch(job, delay: delay, onQueue: onQueue);
  }

  /// Dispatch multiple jobs at once
  static Future<void> dispatchBatch(List<QueueContract.QueueJob> jobs, {Duration? delay}) async {
    await LaravelQueue.Queue.dispatchBatch(jobs, delay: delay);
  }

  // ========= 🌐 URL & Asset Helpers =========

  /// Generate a URL
  static String url(String path, {Map<String, String>? query}) {
    return urlService.url(path, query: query);
  }

  /// Generate an asset URL
  static String asset(String path, {Map<String, String>? query}) {
    return assetService.asset(path, query: query);
  }

  /// Generate a CSS asset URL
  static String css(String path, {Map<String, String>? query}) {
    return assetService.css(path, query: query);
  }

  /// Generate a JavaScript asset URL
  static String js(String path, {Map<String, String>? query}) {
    return assetService.js(path, query: query);
  }

  /// Generate an image asset URL
  static String image(String path, {Map<String, String>? query}) {
    return assetService.image(path, query: query);
  }

  /// Generate a storage URL
  static String storageUrl(String path, {Map<String, String>? query}) {
    return assetService.storage(path, query: query);
  }

  /// Generate a route URL
  static String route(String name,
      {Map<String, String>? parameters, Map<String, String>? query,}) {
    return urlService.route(name, parameters: parameters, query: query);
  }

  /// Store a file
  static Future<String> storeFile(
    String path,
    List<int> bytes, {
    String disk = 'public',
    String? filename,
  }) {
    return assetService.storeFile(path, bytes, disk: disk, filename: filename);
  }

  /// Store a text file
  static Future<String> storeTextFile(
    String path,
    String content, {
    String disk = 'public',
    String? filename,
  }) {
    return assetService.storeTextFile(path, content,
        disk: disk, filename: filename,);
  }

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
