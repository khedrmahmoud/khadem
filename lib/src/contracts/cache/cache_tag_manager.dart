/// Interface for cache tag management.
/// Defines the contract for managing cache tags and group invalidation.
abstract class ICacheTagManager {
  /// Tags a cache item with one or more tags.
  Future<void> tag(String key, List<String> tags);

  /// Removes all cache items associated with the given tag.
  Future<void> forgetByTag(String tag);

  /// Gets all keys associated with a tag.
  Set<String> getKeysForTag(String tag);

  /// Gets all tags for a key.
  Set<String> getTagsForKey(String key);

  /// Removes all tags for a key.
  void removeTagsForKey(String key);

  /// Gets all registered tags.
  Set<String> getAllTags();

  /// Clears all tag associations.
  void clearAllTags();
}
