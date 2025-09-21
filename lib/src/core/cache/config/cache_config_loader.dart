import 'package:khadem/src/contracts/cache/cache_interfaces.dart';

import '../../../contracts/config/config_contract.dart';
import '../../../support/exceptions/cache_exceptions.dart';
import '../cache_drivers/file_cache_driver.dart';
import '../cache_drivers/memory_cache_driver.dart';
import '../cache_drivers/redis_cache_driver.dart';

/// Implementation of cache configuration loader.
/// Handles loading cache configuration and initializing drivers.
class CacheConfigLoader implements ICacheConfigLoader {
  @override
  void loadFromConfig(ConfigInterface config, ICacheDriverRegistry registry) {
    try {
      final driverConfigs = config.get<Map>('cache.drivers') ?? {};
      final defaultDriverName = config.get<String>('cache.default') ?? 'memory';

      // Load all configured drivers
      driverConfigs.forEach((name, settings) {
        final driver = createDriverFromConfig(
          settings['driver'] as String? ?? 'memory',
          settings as Map<String, dynamic>,
        );
        registry.registerDriver(name as String, driver);
      });

      // Register default memory driver if no drivers configured
      if (registry.getDriverNames().isEmpty) {
        registry.registerDriver('memory', MemoryCacheDriver());
      }

      // Set default driver
      registry.setDefaultDriver(defaultDriverName);
    } catch (e) {
      throw CacheException('Failed to load cache configuration: $e');
    }
  }

  @override
  CacheDriver createDriverFromConfig(
      String driverType, Map<String, dynamic> settings,) {
    switch (driverType.toLowerCase()) {
      case 'memory':
        return MemoryCacheDriver();

      case 'file':
        final path = settings['path'] as String?;
        if (path == null || path.isEmpty) {
          throw CacheException('File cache driver requires a "path" setting');
        }
        return FileCacheDriver(cacheDir: path);

      case 'redis':
        final host = settings['host'] as String? ?? 'localhost';
        final port = settings['port'] as int? ?? 6379;
        final password = settings['password'] as String?;
        final database = settings['database'] as int? ?? 0;
        final maxRetries = settings['max_retries'] as int? ?? 3;
        final retryDelay = settings['retry_delay_ms'] as int? ?? 100;

        return RedisCacheDriver(
          host: host,
          port: port,
          password: password,
          database: database,
          maxRetries: maxRetries,
          retryDelay: Duration(milliseconds: retryDelay),
        );

      default:
        throw CacheException('Unknown cache driver: $driverType');
    }
  }
}
