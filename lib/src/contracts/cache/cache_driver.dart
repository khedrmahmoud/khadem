/// An abstract class that defines the interface for cache drivers.
///
/// This class serves as a blueprint for implementing various caching mechanisms,
/// such as in-memory caches, file-based caches, or distributed caches like Redis.
/// Implementations must provide concrete methods for storing, retrieving, and
/// managing cached data with time-to-live (TTL) support.
///
/// Example usage:
/// ```dart
/// class MyCacheDriver implements CacheDriver {
///   // Implementation here
/// }
/// ```
abstract class CacheDriver {
  /// Stores a value in the cache with a specified time-to-live (TTL).
  ///
  /// The [key] is a unique identifier for the cached item. The [value] can be
  /// any dynamic type, and it will be stored for the duration specified by [ttl].
  /// After the TTL expires, the item may be automatically removed from the cache.
  ///
  /// Throws an exception if the [key] is null or empty, or if [ttl] is negative.
  /// Implementations should handle serialization of complex [value] types if needed.
  ///
  /// - Parameters:
  ///   - [key]: A non-null, non-empty string representing the cache key.
  ///   - [value]: The data to be cached, which can be of any type.
  ///   - [ttl]: The duration for which the item should remain in the cache.
  Future<void> put(String key, dynamic value, Duration ttl);

  /// Stores a value in the cache if the key does not exist.
  ///
  /// Returns `true` if the item was actually added, `false` otherwise.
  ///
  /// - Parameters:
  ///   - [key]: A non-null, non-empty string representing the cache key.
  ///   - [value]: The data to be cached.
  ///   - [ttl]: The duration for which the item should remain in the cache.
  Future<bool> add(String key, dynamic value, Duration ttl);

  /// Retrieves a value from the cache by its key.
  ///
  /// Returns the cached value associated with the [key] if it exists and has not expired.
  /// If the [key] does not exist or has expired, returns `null`.
  ///
  /// Throws an exception if the [key] is null or empty.
  /// Implementations should handle deserialization of the stored value if necessary.
  ///
  /// - Parameters:
  ///   - [key]: A non-null, non-empty string representing the cache key.
  /// - Returns: The cached value, or `null` if not found or expired.
  Future<dynamic> get(String key);

  /// Retrieves multiple values from the cache by their keys.
  ///
  /// Returns a map of key-value pairs. Keys not found in the cache will not be present in the returned map.
  ///
  /// - Parameters:
  ///   - [keys]: A list of keys to retrieve.
  Future<Map<String, dynamic>> many(List<String> keys);

  /// Stores multiple values in the cache.
  ///
  /// - Parameters:
  ///   - [values]: A map of key-value pairs to store.
  ///   - [ttl]: The duration for which the items should remain in the cache.
  Future<void> putMany(Map<String, dynamic> values, Duration ttl);

  /// Increment the value of an item in the cache.
  ///
  /// - Parameters:
  ///   - [key]: The key of the item to increment.
  ///   - [amount]: The amount to increment by (default is 1).
  /// - Returns: The new value of the item.
  Future<int> increment(String key, [int amount = 1]);

  /// Decrement the value of an item in the cache.
  ///
  /// - Parameters:
  ///   - [key]: The key of the item to decrement.
  ///   - [amount]: The amount to decrement by (default is 1).
  /// - Returns: The new value of the item.
  Future<int> decrement(String key, [int amount = 1]);

  /// Retrieve an item from the cache and delete it.
  ///
  /// - Parameters:
  ///   - [key]: The key of the item to retrieve and delete.
  /// - Returns: The value of the item, or `null` if not found.
  Future<dynamic> pull(String key);

  /// Removes a value from the cache by its key.
  ///
  /// Deletes the cached item associated with the [key] if it exists.
  /// If the [key] does not exist, this operation should be a no-op (no exception thrown).
  ///
  /// Throws an exception if the [key] is null or empty.
  ///
  /// - Parameters:
  ///   - [key]: A non-null, non-empty string representing the cache key.
  Future<void> forget(String key);

  /// Checks if a key exists in the cache and has not expired.
  ///
  /// Returns `true` if the [key] is present in the cache and its TTL has not expired,
  /// otherwise returns `false`.
  ///
  /// Throws an exception if the [key] is null or empty.
  ///
  /// - Parameters:
  ///   - [key]: A non-null, non-empty string representing the cache key.
  /// - Returns: `true` if the key exists and is valid, `false` otherwise.
  Future<bool> has(String key);

  /// Clears all items from the cache.
  ///
  /// Removes all cached data, effectively resetting the cache to an empty state.
  /// This operation is irreversible and should be used with caution.
  ///
  /// Implementations may throw exceptions if the clear operation fails due to
  /// underlying storage issues (e.g., disk errors).
  Future<void> clear();
}
