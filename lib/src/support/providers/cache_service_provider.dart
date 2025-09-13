import 'package:khadem/src/contracts/cache/cache_interfaces.dart';
import 'package:khadem/src/contracts/container/container_interface.dart';
import 'package:khadem/src/contracts/provider/service_provider.dart';
import 'package:khadem/src/core/cache/config/cache_config_loader.dart';
import 'package:khadem/src/core/cache/managers/cache_driver_registry.dart';
import 'package:khadem/src/core/cache/managers/cache_manager.dart';
import 'package:khadem/src/core/cache/managers/cache_statistics_manager.dart';
import 'package:khadem/src/core/cache/managers/cache_tag_manager.dart';
import 'package:khadem/src/core/cache/managers/cache_validator.dart';


/// Service provider for cache system.
/// Registers all cache-related dependencies in the service container.
///
/// This provider follows the dependency injection pattern and registers:
/// - CacheDriverRegistry: Manages cache driver registration
/// - CacheStatisticsManager: Handles cache performance metrics
/// - CacheTagManager: Manages cache tags for group invalidation
/// - CacheValidator: Validates cache operations and inputs
/// - CacheConfigLoader: Loads cache configuration and initializes drivers
/// - CacheManager: Main facade for cache operations
///
/// ## Usage
///
/// ```dart
/// // Register the service provider
/// final container = ContainerInterface();
/// container.register(CacheServiceProvider());
///
/// // Resolve the cache manager
/// final cache = container.resolve<CacheManager>();
/// ```
class CacheServiceProvider implements ServiceProvider {
  @override
  void register(ContainerInterface container) {
    // Register cache driver registry
    container.singleton<ICacheDriverRegistry>(
      (c) => CacheDriverRegistry(),
    );

    // Register cache statistics manager
    container.singleton<ICacheStatisticsManager>(
      (c) => CacheStatisticsManager(),
    );

    // Register cache tag manager
    container.singleton<ICacheTagManager>(
      (c) => CacheTagManager(),
    );

    // Register cache validator
    container.singleton<ICacheValidator>(
      (c) => CacheValidator(),
    );

    // Register cache config loader
    container.singleton<ICacheConfigLoader>(
      (c) => CacheConfigLoader(),
    );

    // Register cache manager with all dependencies
    container.singleton<CacheManager>(
      (c) => CacheManager(
        driverRegistry: c.resolve<ICacheDriverRegistry>(),
        statisticsManager: c.resolve<ICacheStatisticsManager>(),
        tagManager: c.resolve<ICacheTagManager>(),
        configLoader: c.resolve<ICacheConfigLoader>(),
        validator: c.resolve<ICacheValidator>(),
      ),
    );

    // Register interface bindings for easier resolution
    container.bind<ICacheManager>(
      (c) => c.resolve<CacheManager>(),
    );
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    // Initialize default cache configuration if available
    final config = container.has('config') ? container.resolve('config') : null;
    if (config != null) {
      final cacheManager = container.resolve<CacheManager>();
      // Load configuration if config is available
      // This assumes the config has a 'cache' section
      try {
        cacheManager.loadFromConfig(config);
      } catch (e) {
        // Configuration loading failed, but don't break the application
        // The cache system can still be used with manual driver registration
      }
    }
  }

  @override
  bool get isDeferred => false;
}