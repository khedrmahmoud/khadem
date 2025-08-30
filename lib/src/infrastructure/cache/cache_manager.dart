import 'dart:async';

import '../../contracts/cache/cache_driver.dart';
import '../../contracts/config/config_contract.dart';
import '../../support/cache_drivers/file_cache_driver.dart';
import '../../support/cache_drivers/hybrid_cache_driver.dart';
import '../../support/cache_drivers/memory_cache_driver.dart';
import '../../support/cache_drivers/redis_cache_driver.dart';
import '../../support/exceptions/cache_exceptions.dart';

/// Cache manager that handles multiple cache drivers and automatic cache invalidation.
class CacheManager {
  final Map<String, CacheDriver> _drivers = {};
  late CacheDriver _defaultDriver;

  /// Registers a cache driver with the given name.
  void registerDriver(String name, CacheDriver driver) {
    _drivers[name] = driver;
    if (_drivers.length == 1) {
      _defaultDriver = driver;
    }
  }

  void loadFromConfig(ConfigInterface config) {
    final driverConfigs = config.get<Map>('cache.drivers') ?? {};
    final defaultDriverName = config.get<String>('cache.default') ?? 'file';

    // Built-in drivers
    driverConfigs.forEach(( name, settings) {
      final driverType = settings['driver'];

      switch (driverType) {
        case 'file':
          registerDriver(name as String, FileCacheDriver());
          break;
        case 'memory':
          registerDriver(name as String, MemoryCacheDriver());
          break;
        case 'hybrid':
          registerDriver(
            name as String,
            HybridCacheDriver(filePath: settings['path'] as String),
          );
          break;
        case 'redis':
          registerDriver(
            name as String,
            RedisCacheDriver(
              host: settings['host'] as String,
              port: settings['port'] as int,
            ),
          );
          break;
        default:
          throw CacheException('Unknown cache driver: $driverType');
      }
    });

    setDefaultDriver(defaultDriverName);
  }

  /// Sets the default cache driver.
  void setDefaultDriver(String name) {
    if (!_drivers.containsKey(name)) {
      throw CacheException('Cache driver "$name" not registered');
    }
    _defaultDriver = _drivers[name]!;
  }

  /// Gets a specific cache driver instance.
  CacheDriver driver([String? name]) {
    if (name != null) {
      if (!_drivers.containsKey(name)) {
        throw CacheException('Cache driver "$name" not registered');
      }
      return _drivers[name]!;
    }
    return _defaultDriver;
  }

  /// Stores a value in the cache using the default driver.
  Future<void> put(String key, dynamic value, Duration ttl) {
    return _defaultDriver.put(key, value, ttl);
  }

  /// Retrieves a value from the cache using the default driver.
  Future<dynamic> get(String key) {
    return _defaultDriver.get(key);
  }

  /// Removes a value from the cache using the default driver.
  Future<void> forget(String key) {
    return _defaultDriver.forget(key);
  }

  /// Checks if a key exists in the cache using the default driver.
  Future<bool> has(String key) {
    return _defaultDriver.has(key);
  }

  /// Clears all items from the cache using the default driver.
  Future<void> clear() {
    return _defaultDriver.clear();
  }

  /// Stores a value in the cache forever using the default driver.
  Future<void> forever(String key, dynamic value) {
    return put(key, value, const Duration(days: 365 * 10));
  }

  /// Retrieves a value from the cache or stores the default value if it doesn't exist.
  Future<dynamic> remember(
      String key, Duration ttl, Future<dynamic> Function() callback,) async {
    if (await has(key)) {
      return get(key);
    }

    final value = await callback();
    await put(key, value, ttl);
    return value;
  }
}
