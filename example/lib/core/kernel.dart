import 'package:khadem/khadem.dart'
    show
        DatabaseServiceProvider,
        Khadem,
        LoggingMiddleware,
        Middleware,
        MigrationFile,
        ServiceProvider,
        SetLocaleMiddleware,
        QueueServiceProvider,
        AuthServiceProvider,
        CoreServiceProvider,
        CacheServiceProvider;

import '../app/http/middleware/cors_middleware.dart';
import '../app/providers/app_service_provider.dart';
import '../app/providers/event_service_provider.dart';
import '../app/providers/observer_service_provider.dart';
import '../app/providers/scheduler_service_provider.dart';
import '../config/app.dart';
import '../database/migrations/migrations.dart';
 

class Kernel {
  Kernel._();

  /// Core service providers (framework essentials)
  static List<ServiceProvider> get coreProviders => [
        CoreServiceProvider(),
        CacheServiceProvider(),
        QueueServiceProvider(),
        AuthServiceProvider(),
        DatabaseServiceProvider(),
      ];

  /// Application service providers (user-managed)
  static List<ServiceProvider> get applicationProviders => [
        AppServiceProvider(),
        EventServiceProvider(),
        SchedulerServiceProvider(),
        ObserverServiceProvider(), // Register model observers
        // Add your application service providers here
      ];

  /// All service providers combined
  static List<ServiceProvider> get allProviders => [
        ...coreProviders,
        ...applicationProviders,
      ];

  /// List of global middlewares
  static List<Middleware> get middlewares => [
        CorsMiddleware(),
        LoggingMiddleware(),
        SetLocaleMiddleware(),
        // Add middleware here
      ];

  ///  Configs
  static final Map<String, Map<String, dynamic>> configs = AppConfig.configs;

  /// Migrations
  static List<MigrationFile> migrations = migrationsFiles;

  /// Bootstrap the application with all service providers
  static Future<void> bootstrap() async {
    // Register application services
    Khadem.register(allProviders);

    // 🔌 Register the config registry (static Dart maps)
    Khadem.loadConfigs(configs);

    // Boot all services
    await Khadem.boot();

    final config = Khadem.config;

    // 📦 Register the DB migrations
    Khadem.migrator.registerAll(migrations);

    // 📦 Register the DB seeders
    Khadem.seeder.registerAll([]);

    if (config.get<bool>('database.run_migrations', false)!) {
      await Khadem.migrator.upAll();
    }

    if (config.get<bool>('database.run_seeders', false)!) {
      await Khadem.seeder.runAll();
    }
  }
}
