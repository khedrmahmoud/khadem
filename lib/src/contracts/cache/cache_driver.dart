/// Abstract class defining the interface for cache drivers.
abstract class CacheDriver {
  /// Stores a value in the cache with a TTL.
  Future<void> put(String key, dynamic value, Duration ttl);

  /// Retrieves a value from the cache.
  Future<dynamic> get(String key);

  /// Removes a value from the cache.
  Future<void> forget(String key);

  /// Checks if a key exists in the cache.
  Future<bool> has(String key);

  /// Clears all items from the cache.
  Future<void> clear();
}
