import 'dart:async';

import 'package:khadem/src/core/cache/cache_stats.dart';

import '../../../contracts/cache/cache_config_loader.dart';
import '../../../contracts/cache/cache_driver.dart';
import '../../../contracts/cache/cache_driver_registry.dart';
import '../../../contracts/cache/cache_manager_contract.dart';
import '../../../contracts/cache/cache_statistics_manager.dart';
import '../../../contracts/cache/cache_tag_manager.dart';
import '../../../contracts/cache/cache_validator.dart';
import '../../../contracts/config/config_contract.dart';
import '../../../support/exceptions/cache_exceptions.dart';

/// Cache manager that implements a clean facade pattern.
/// Orchestrates all cache operations through modular managers following SOLID principles.
///
/// The CacheManager provides a unified interface for caching operations across different
/// storage backends including memory, file system, and Redis. It supports multiple
/// cache drivers, automatic TTL (time-to-live) management, and cache tagging for
/// efficient cache invalidation.
///
/// ## Features
///
/// - **Modular Architecture**: Uses dependency injection with separate managers for each responsibility
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
/// // Create managers
/// final registry = CacheDriverRegistry();
/// final statsManager = CacheStatisticsManager();
/// final tagManager = CacheTagManager();
/// final configLoader = CacheConfigLoader();
/// final validator = CacheValidator();
///
/// // Create cache manager
/// final cache = CacheManager(
///   driverRegistry: registry,
///   statisticsManager: statsManager,
///   tagManager: tagManager,
///   configLoader: configLoader,
///   validator: validator,
/// );
///
/// // Register a memory cache driver
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
class CacheManager implements ICacheManager {
  final ICacheDriverRegistry _driverRegistry;
  final ICacheStatisticsManager _statisticsManager;
  final ICacheTagManager _tagManager;
  final ICacheConfigLoader _configLoader;
  final ICacheValidator _validator;

  /// Creates a new CacheManager with the required managers.
  ///
  /// All managers must be provided through dependency injection to ensure
  /// proper separation of concerns and testability.
  CacheManager({
    required ICacheDriverRegistry driverRegistry,
    required ICacheStatisticsManager statisticsManager,
    required ICacheTagManager tagManager,
    required ICacheConfigLoader configLoader,
    required ICacheValidator validator,
  })  : _driverRegistry = driverRegistry,
        _statisticsManager = statisticsManager,
        _tagManager = tagManager,
        _configLoader = configLoader,
        _validator = validator;

  /// Registers a cache driver with the given name.
  ///
  /// The first registered driver automatically becomes the default driver.
  /// Use [setDefaultDriver] to change the default driver later.
  ///
  /// Throws [CacheException] if the driver name is empty or already registered.
  void registerDriver(String name, CacheDriver driver) {
    _validator.validateDriverName(name);
    _driverRegistry.registerDriver(name, driver);
    _statisticsManager.updateStats(name, hit: false, operation: 'register');
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
    _configLoader.loadFromConfig(config, _driverRegistry);
  }

  /// Sets the default cache driver.
  ///
  /// All cache operations will use this driver unless a specific driver
  /// is requested using the [driver] method.
  ///
  /// Throws [CacheException] if the driver is not registered.
  void setDefaultDriver(String name) {
    _validator.validateDriverName(name);
    _driverRegistry.setDefaultDriver(name);
  }

  /// Gets a specific cache driver instance.
  ///
  /// If [name] is provided, returns the driver with that name.
  /// Otherwise, returns the default driver.
  ///
  /// Throws [CacheException] if the requested driver is not registered.
  @override
  CacheDriver driver([String? name]) {
    if (name != null) {
      _validator.validateDriverName(name);
      final driver = _driverRegistry.getDriver(name);
      if (driver == null) {
        throw CacheException('Cache driver "$name" not registered');
      }
      return driver;
    }
    return _driverRegistry.getDefaultDriver();
  }

  /// Stores a value in the cache using the default driver.
  ///
  /// The [key] must be a non-empty string. The [value] can be any serializable
  /// object. The [ttl] specifies how long the item should remain in the cache.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    _validator.validateKey(key);
    _validator.validateTtl(ttl);

    try {
      final driver = _driverRegistry.getDefaultDriver();
      await driver.put(key, value, ttl);
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'put',
      );
    } catch (e) {
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'put',
        error: true,
      );
      throw CacheException('Failed to store cache item "$key": $e');
    }
  }

  /// Retrieves a value from the cache using the default driver.
  ///
  /// Returns the cached value if it exists and hasn't expired, otherwise returns null.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  @override
  Future<dynamic> get(String key) async {
    _validator.validateKey(key);

    try {
      final driver = _driverRegistry.getDefaultDriver();
      final value = await driver.get(key);
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: value != null,
        operation: 'get',
      );
      return value;
    } catch (e) {
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'get',
        error: true,
      );
      throw CacheException('Failed to retrieve cache item "$key": $e');
    }
  }

  /// Removes a value from the cache using the default driver.
  ///
  /// If the key doesn't exist, this operation is a no-op.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  @override
  Future<void> forget(String key) async {
    _validator.validateKey(key);

    try {
      final driver = _driverRegistry.getDefaultDriver();
      await driver.forget(key);
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'forget',
      );

      // Remove tags for this key
      _tagManager.removeTagsForKey(key);
    } catch (e) {
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'forget',
        error: true,
      );
      throw CacheException('Failed to remove cache item "$key": $e');
    }
  }

  /// Checks if a key exists in the cache using the default driver.
  ///
  /// Returns true if the key exists and hasn't expired, false otherwise.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  @override
  Future<bool> has(String key) async {
    _validator.validateKey(key);

    try {
      final driver = _driverRegistry.getDefaultDriver();
      final exists = await driver.has(key);
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: exists,
        operation: 'has',
      );
      return exists;
    } catch (e) {
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'has',
        error: true,
      );
      throw CacheException('Failed to check cache item "$key": $e');
    }
  }

  /// Clears all items from the cache using the default driver.
  ///
  /// This operation removes all cached data and cannot be undone.
  ///
  /// Throws [CacheException] if the operation fails.
  @override
  Future<void> clear() async {
    try {
      final driver = _driverRegistry.getDefaultDriver();
      await driver.clear();
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'clear',
      );

      // Clear all tags
      _tagManager.clearAllTags();
    } catch (e) {
      _statisticsManager.updateStats(
        _driverRegistry.getDefaultDriverName(),
        hit: false,
        operation: 'clear',
        error: true,
      );
      throw CacheException('Failed to clear cache: $e');
    }
  }

  /// Stores a value in the cache forever using the default driver.
  ///
  /// The item will remain in the cache indefinitely until manually removed
  /// or the cache is cleared.
  ///
  /// Throws [CacheException] if the key is empty or if the operation fails.
  @override
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
  @override
  Future<dynamic> remember(
    String key,
    Duration ttl,
    Future<dynamic> Function() callback,
  ) async {
    _validator.validateKey(key);
    _validator.validateTtl(ttl);

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
  @override
  Future<void> tag(String key, List<String> tags) async {
    _validator.validateKey(key);
    _validator.validateTags(tags);
    await _tagManager.tag(key, tags);
  }

  /// Removes all cache items associated with the given tag.
  ///
  /// This is useful for invalidating groups of related cache items.
  ///
  /// Throws [CacheException] if the operation fails.
  @override
  Future<void> forgetByTag(String tag) async {
    final keys = _tagManager.getKeysForTag(tag);

    // Remove each key from cache
    for (final key in keys) {
      try {
        await forget(key);
      } catch (e) {
        // Continue with other keys even if one fails
        // Log error or handle as needed
      }
    }

    // Remove tag associations
    await _tagManager.forgetByTag(tag);
  }

  /// Gets all registered driver names.
  @override
  List<String> get driverNames => _driverRegistry.getDriverNames();

  /// Gets the name of the current default driver.
  @override
  String get defaultDriverName => _driverRegistry.getDefaultDriverName();

  /// Gets cache statistics for the default driver.
  @override
  CacheStats get stats =>
      _statisticsManager.getStats(_driverRegistry.getDefaultDriverName());

  /// Gets cache statistics for all drivers.
  @override
  Map<String, CacheStats> get allStats => _statisticsManager.getAllStats();
}
