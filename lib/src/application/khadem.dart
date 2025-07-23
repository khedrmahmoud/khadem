import '../contracts/config/config_contract.dart';
import '../contracts/env/env_interface.dart';
import '../contracts/container/container_interface.dart';
import '../core/container/container_provider.dart';
import '../core/database/database.dart';
import '../core/database/migration/migrator.dart';
import '../core/database/migration/seeder.dart';
import '../contracts/events/event_system_interface.dart';
import '../core/http/middleware/middleware_pipeline.dart';
import '../contracts/provider/service_provider.dart';
import '../modules/auth/services/auth_manager.dart';
import '../support/providers/core_service_provider.dart';
import '../support/providers/database_service_provider.dart';
import '../support/providers/queue_service_provider.dart';
import '../core/service_provider/service_provider_manager.dart';

import '../infrastructure/cache/cache_manager.dart';
import '../infrastructure/logging/logger.dart';
import '../infrastructure/queue/queue_manager.dart';
import '../modules/auth/core/auth_service_provider.dart';

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

  /// Registers core service providers (basic, queue, auth).
  static Future<void> registerCoreServices() async {
    register([
      CoreServiceProvider(),
      QueueServiceProvider(),
      AuthServiceProvider(),
      // Optionally: LangServiceProvider()
    ]);
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

  /// Register and boot database-related services.
  static Future<void> registerDatabaseServices() async {
    final dbProvider = DatabaseServiceProvider();
    register([dbProvider]);
    await dbProvider.boot(container);
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
  static AuthManager get auth => container.resolve<AuthManager>();
}
