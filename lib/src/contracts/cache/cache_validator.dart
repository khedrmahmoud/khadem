/// Interface for cache validation.
/// Defines the contract for validating cache operations and inputs.
abstract class ICacheValidator {
  /// Validates a cache key.
  /// Throws [CacheException] if the key is invalid.
  void validateKey(String key);

  /// Validates a TTL duration.
  /// Throws [CacheException] if the TTL is invalid.
  void validateTtl(Duration ttl);

  /// Validates a driver name.
  /// Throws [CacheException] if the driver name is invalid.
  void validateDriverName(String name);

  /// Validates cache tags.
  /// Throws [CacheException] if any tag is invalid.
  void validateTags(List<String> tags);
}
