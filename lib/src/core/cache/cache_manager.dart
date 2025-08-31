import 'dart:async';

import '../../contracts/cache/cache_driver.dart';
import '../../contracts/config/config_contract.dart';
import '../../support/cache_drivers/file_cache_driver.dart';
import '../../support/cache_drivers/hybrid_cache_driver.dart';
import '../../support/cache_drivers/memory_cache_driver.dart';
import '../../support/cache_drivers/redis_cache_driver.dart';
import '../../support/exceptions/cache_exceptions.dart';

/// Cache manager that handles multiple cache drivers and automatic cache invalidation.
///
/// The CacheManager provides a unified interface for caching operations across different
/// storage backends including memory, file system, and Redis. It supports multiple
/// cache drivers, automatic TTL (time-to-live) management, and cache tagging for
/// efficient cache invalidation.
///
/// ## Features
///
/// - **Multiple Drivers**: Support for memory, file, hybrid, and Redis cache drivers
/// - **TTL Management**: Automatic expiration of cached items
/// - **Cache Tags**: Group related cache items for bulk invalidation
/// - **Configuration**: Load cache settings from configuration files
/// - **Statistics**: Track cache hits, misses, and performance metrics
/// - **Error Handling**: Robust error handling with custom exceptions
///
/// ## Basic Usage
///
/// ```dart
/// // Register a memory cache driver
/// final cache = CacheManager();
/// cache.registerDriver('memory', MemoryCacheDriver());
/// cache.setDefaultDriver('memory');
///
/// // Store and retrieve data
/// await cache.put('user:123', {'name': 'John', 'age': 30}, Duration(hours: 1));
/// final user = await cache.get('user:123');
///
/// // Use remember pattern
/// final data = await cache.remember('expensive_data', Duration(minutes: 30), () async {
///   return await fetchExpensiveData();
/// });
/// ```
///
/// ## Configuration
///
/// Cache drivers can be configured through the application's configuration:
///
/// ```yaml
/// cache:
///   default: memory
///   drivers:
///     memory:
///       driver: memory
///     file:
///       driver: file
///       path: ./storage/cache
///     redis:
///       driver: redis
///       host: localhost
///       port: 6379
/// ```
class CacheManager {
  final Map<String, CacheDriver> _drivers = {};
  final Map<String, Set<String>> _tags = {};
  final Map<String, DateTime> _tagTimestamps = {};
  late CacheDriver _defaultDriver;
  final Map<String, CacheStats> _stats = {};

  /// Statistics for cache operations
  CacheStats get stats {
    try {
      return _stats[_defaultDriverName] ?? CacheStats.empty();
    } catch (e) {
      return CacheStats.empty();
    }
  }

  String get _defaultDriverName {
    if (_drivers.isEmpty) {
      throw StateError('No cache drivers registered');
    }
    return _drivers.entries.firstWhere((e) => e.value == _defaultDriver).key;
  }

  /// Registers a cache driver with the given name.
  ///
  /// The first registered driver automatically becomes the default driver.
  /// Use [setDefaultDriver] to change the default driver later.
  ///
  /// Throws [CacheException] if the driver name is empty or already registered.
  void registerDriver(String name, CacheDriver driver) {
    if (name.isEmpty) {
      throw CacheException('Cache driver name cannot be empty');
    }
    if (_drivers.containsKey(name)) {
      throw CacheException('Cache driver "$name" is already registered');
    }

    _drivers[name] = driver;
    _stats[name] = CacheStats.empty();

    if (_drivers.length == 1) {
      _defaultDriver = driver;
    }
  }

  /// Loads cache configuration from the application's config.
  ///
  /// This method reads cache settings from the configuration and automatically
  /// registers the appropriate cache drivers based on the configuration.
  ///
  /// The configuration should have the following structure:
  /// ```yaml
  /// cache:
  ///   default: memory
  ///   drivers:
  ///     memory:
  ///       driver: memory
  ///     file:
  ///       driver: file
  ///       path: ./storage/cache
  /// ```
  ///
  /// Throws [CacheException] if the configuration is invalid or if a driver
  /// cannot be initialized.
  void loadFromConfig(ConfigInterface config) {
    try {
      final driverConfigs = config.get<Map>('cache.drivers') ?? {};
      final defaultDriverName = config.get<String>('cache.default') ?? 'memory';

      // Built-in drivers
      driverConfigs.forEach((name, settings) {
        final driverType = settings['driver'];

        switch (driverType) {
          case 'file':
            final path = settings['path'] as String?;
            if (path == null || path.isEmpty) {
              throw CacheException('File cache driver requires a "path" setting');
            }
            registerDriver(name as String, FileCacheDriver(config: {'path': path}));
            break;
          case 'memory':
            registerDriver(name as String, MemoryCacheDriver());
            break;
          case 'hybrid':
            final path = settings['path'] as String?;
            if (path == null || path.isEmpty) {
              throw CacheException('Hybrid cache driver requires a "path" setting');
            }
            registerDriver(
              name as String,
              HybridCacheDriver(filePath: path),
            );
            break;
          case 'redis':
            final host = settings['host'] as String? ?? 'localhost';
            final port = settings['port'] as int? ?? 6379;
            registerDriver(
              name as String,
              RedisCacheDriver(host: host, port: port),
            );
            break;
          default:
            throw CacheException('Unknown cache driver: $driverType');
        }
      });

      if (_drivers.isEmpty) {
        // Register default memory driver if no drivers configured
        registerDriver('memory', MemoryCacheDriver());
      }

      setDefaultDriver(defaultDriverName);
    } catch (e) {
      throw CacheException('Failed to load cache configuration: $e');
    }
  }

  /// Sets the default cache driver.
  ///
  /// All cache operations will use this driver unless a specific driver
  /// is requested using the [driver] method.
  ///
  /// Throws [CacheException] if the driver is not registered.
  void setDefaultDriver(String name) {
    if (!_drivers.containsKey(name)) {
      throw CacheException('Cache driver "$name" not registered');
    }
    _defaultDriver = _drivers[name]!;
  }

  /// Gets a specific cache driver instance.
  ///
  /// If [name] is provided, returns the driver with that name.
  /// Otherwise, returns the default driver.
  ///
  /// Throws [CacheException] if the requested driver is not registered.
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
  ///
  /// The [key] must be a non-empty string. The [value] can be any serializable
  /// object. The [ttl] specifies how long the item should remain in the cache.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  Future<void> put(String key, dynamic value, Duration ttl) async {
    _validateKey(key);
    try {
      await _defaultDriver.put(key, value, ttl);
      _updateStats(hit: false, operation: 'put');
    } catch (e) {
      _updateStats(hit: false, operation: 'put', error: true);
      throw CacheException('Failed to store cache item "$key": $e');
    }
  }

  /// Retrieves a value from the cache using the default driver.
  ///
  /// Returns the cached value if it exists and hasn't expired, otherwise returns null.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  Future<dynamic> get(String key) async {
    _validateKey(key);
    try {
      final value = await _defaultDriver.get(key);
      _updateStats(hit: value != null, operation: 'get');
      return value;
    } catch (e) {
      _updateStats(hit: false, operation: 'get', error: true);
      throw CacheException('Failed to retrieve cache item "$key": $e');
    }
  }

  /// Removes a value from the cache using the default driver.
  ///
  /// If the key doesn't exist, this operation is a no-op.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  Future<void> forget(String key) async {
    _validateKey(key);
    try {
      await _defaultDriver.forget(key);
      _updateStats(hit: false, operation: 'forget');
    } catch (e) {
      _updateStats(hit: false, operation: 'forget', error: true);
      throw CacheException('Failed to remove cache item "$key": $e');
    }
  }

  /// Checks if a key exists in the cache using the default driver.
  ///
  /// Returns true if the key exists and hasn't expired, false otherwise.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  Future<bool> has(String key) async {
    _validateKey(key);
    try {
      final exists = await _defaultDriver.has(key);
      _updateStats(hit: exists, operation: 'has');
      return exists;
    } catch (e) {
      _updateStats(hit: false, operation: 'has', error: true);
      throw CacheException('Failed to check cache item "$key": $e');
    }
  }

  /// Clears all items from the cache using the default driver.
  ///
  /// This operation removes all cached data and cannot be undone.
  ///
  /// Throws [CacheException] if the operation fails.
  Future<void> clear() async {
    try {
      await _defaultDriver.clear();
      _updateStats(hit: false, operation: 'clear');
    } catch (e) {
      _updateStats(hit: false, operation: 'clear', error: true);
      throw CacheException('Failed to clear cache: $e');
    }
  }

  /// Stores a value in the cache forever using the default driver.
  ///
  /// The item will remain in the cache indefinitely until manually removed
  /// or the cache is cleared.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  Future<void> forever(String key, dynamic value) async {
    await put(key, value, const Duration(days: 365 * 10));
  }

  /// Retrieves a value from the cache or stores the default value if it doesn't exist.
  ///
  /// This is a common caching pattern that checks for a cached value first,
  /// and if not found, executes the callback function to compute the value,
  /// stores it in the cache, and returns it.
  ///
  /// The [callback] function should return a Future that resolves to the value
  /// to be cached.
  ///
  /// Throws [CacheException] if the key is empty or if any operation fails.
  Future<dynamic> remember(
    String key,
    Duration ttl,
    Future<dynamic> Function() callback,
  ) async {
    _validateKey(key);
    try {
      if (await has(key)) {
        return await get(key);
      }

      final value = await callback();
      await put(key, value, ttl);
      return value;
    } catch (e) {
      throw CacheException('Failed to remember cache item "$key": $e');
    }
  }

  /// Tags a cache item with one or more tags for group invalidation.
  ///
  /// Cache tags allow you to group related cache items and invalidate them
  /// all at once using [forgetByTag].
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  Future<void> tag(String key, List<String> tags) async {
    _validateKey(key);
    for (final tag in tags) {
      _tags.putIfAbsent(tag, () => {}).add(key);
    }
    _tagTimestamps[key] = DateTime.now();
  }

  /// Removes all cache items associated with the given tag.
  ///
  /// This is useful for invalidating groups of related cache items.
  ///
  /// Throws [CacheException] if the operation fails.
  Future<void> forgetByTag(String tag) async {
    final keys = _tags[tag];
    if (keys != null) {
      for (final key in keys) {
        await forget(key);
      }
      _tags.remove(tag);
    }
  }

  /// Gets all registered driver names.
  List<String> get driverNames => _drivers.keys.toList();

  /// Gets the name of the current default driver.
  String get defaultDriverName {
    if (_drivers.isEmpty) {
      throw CacheException('No cache drivers registered');
    }
    return _defaultDriverName;
  }

  /// Gets cache statistics for all drivers.
  Map<String, CacheStats> get allStats => Map.unmodifiable(_stats);

  /// Validates that a cache key is not empty.
  void _validateKey(String key) {
    if (key.isEmpty) {
      throw CacheException('Cache key cannot be empty');
    }
  }

  /// Updates cache statistics for the current operation.
  void _updateStats({
    required bool hit,
    required String operation,
    bool error = false,
  }) {
    final driverName = _defaultDriverName;
    final currentStats = _stats[driverName] ?? CacheStats.empty();

    _stats[driverName] = CacheStats(
      hits: currentStats.hits + (operation == 'get' || operation == 'has' ? (hit ? 1 : 0) : 0),
      misses: currentStats.misses + (operation == 'get' || operation == 'has' ? (hit ? 0 : 1) : 0),
      puts: currentStats.puts + (operation == 'put' ? 1 : 0),
      forgets: currentStats.forgets + (operation == 'forget' ? 1 : 0),
      clears: currentStats.clears + (operation == 'clear' ? 1 : 0),
      errors: currentStats.errors + (error ? 1 : 0),
    );
  }
}

/// Statistics for cache operations.
class CacheStats {
  final int hits;
  final int misses;
  final int puts;
  final int forgets;
  final int clears;
  final int errors;

  const CacheStats({
    required this.hits,
    required this.misses,
    required this.puts,
    required this.forgets,
    required this.clears,
    required this.errors,
  });

  factory CacheStats.empty() => const CacheStats(
        hits: 0,
        misses: 0,
        puts: 0,
        forgets: 0,
        clears: 0,
        errors: 0,
      );

  double get hitRate => hits + misses > 0 ? hits / (hits + misses) : 0.0;

  @override
  String toString() =>
      'CacheStats(hits: $hits, misses: $misses, puts: $puts, forgets: $forgets, clears: $clears, errors: $errors, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
}
