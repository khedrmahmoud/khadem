/// Cache driver contract that defines the required methods for any cache implementation
abstract class CacheContract {
  /// Get a value from cache
  Future<T?> get<T>(String key);

  /// Set a value in cache
  Future<bool> set<T>(String key, T value, {Duration? ttl});

  /// Check if a key exists in cache
  Future<bool> has(String key);

  /// Remove a key from cache
  Future<bool> remove(String key);

  /// Clear all items from cache
  Future<bool> clear();

  /// Get many items from cache
  Future<Map<String, T?>> getMany<T>(List<String> keys);

  /// Set many items in cache
  Future<bool> setMany<T>(Map<String, T> values, {Duration? ttl});

  /// Remove many items from cache
  Future<bool> removeMany(List<String> keys);

  /// Increment a value in cache
  Future<int> increment(String key, [int value = 1]);

  /// Decrement a value in cache
  Future<int> decrement(String key, [int value = 1]);
}
