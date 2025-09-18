import 'package:khadem/src/core/cache/cache_stats.dart';

import 'cache_driver.dart';

/// Interface for the main cache facade.
/// Defines the contract for the unified cache API.
abstract class ICacheManager {
  /// Stores a value in the cache.
  Future<void> put(String key, dynamic value, Duration ttl);

  /// Retrieves a value from the cache.
  Future<dynamic> get(String key);

  /// Removes a value from the cache.
  Future<void> forget(String key);

  /// Checks if a key exists in the cache.
  Future<bool> has(String key);

  /// Clears all items from the cache.
  Future<void> clear();

  /// Stores a value in the cache forever.
  Future<void> forever(String key, dynamic value);

  /// Retrieves a value or stores the default value if it doesn't exist.
  Future<dynamic> remember(String key, Duration ttl, Future<dynamic> Function() callback);

  /// Tags a cache item with one or more tags.
  Future<void> tag(String key, List<String> tags);

  /// Removes all cache items associated with the given tag.
  Future<void> forgetByTag(String tag);

  /// Gets cache statistics.
  CacheStats get stats;

  /// Gets all registered driver names.
  List<String> get driverNames;

  /// Gets the name of the current default driver.
  String get defaultDriverName;

  /// Gets cache statistics for all drivers.
  Map<String, CacheStats> get allStats;

  /// Gets a specific cache driver instance.
  CacheDriver driver([String? name]);
}