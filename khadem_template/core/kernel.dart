import 'package:khadem/khadem_dart.dart'
    show
        Middleware,
        ServiceProvider,
        MigrationFile,
        LoggingMiddleware,
        SetLocaleMiddleware;
import '../app/Providers/event_service_provider.dart';
import '../app/Providers/scheduler_service_provider.dart';
import '../app/http/middleware/cors_middleware.dart';
import '../app/providers/app_service_provider.dart';
import '../config/app.dart';
import '../database/migrations/migrations.dart';

class Kernel {
  Kernel._();

  /// Providers
  static List<ServiceProvider> providers = [
    AppServiceProvider(),
    EventServiceProvider(),
    SchedulerServiceProvider(),
    // Add ServiceProvider here
  ];

  static List<ServiceProvider> lazyProviders = [
    // Add ServiceProvider here
  ];

  /// List of global middlewares
  static List<Middleware> get middlewares => [
        CorsMiddleware(),
        LoggingMiddleware(),
        SetLocaleMiddleware()
        // Add middleware here
      ];

  ///  Configs
  static final Map<String, Map<String, dynamic>> configs = AppConfig.configs;

  /// Migrations
  static List<MigrationFile> migrations = migrationFiles;
}
