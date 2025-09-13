import '../../../support/exceptions/cache_exceptions.dart';
import '../../../contracts/cache/cache_tag_manager.dart';

/// Implementation of cache tag manager.
/// Manages cache tags for group invalidation and key organization.
class CacheTagManager implements ICacheTagManager {
  final Map<String, Set<String>> _tagToKeys = {};
  final Map<String, Set<String>> _keyToTags = {};
  final Map<String, DateTime> _tagTimestamps = {};

  @override
  Future<void> tag(String key, List<String> tags) async {
    if (key.isEmpty) {
      throw CacheException('Cache key cannot be empty');
    }

    for (final tag in tags) {
      if (tag.isEmpty) {
        throw CacheException('Cache tag cannot be empty');
      }

      // Add key to tag mapping
      _tagToKeys.putIfAbsent(tag, () => {}).add(key);

      // Add tag to key mapping
      _keyToTags.putIfAbsent(key, () => {}).add(tag);
    }

    // Update timestamp for the key
    _tagTimestamps[key] = DateTime.now();
  }

  @override
  Future<void> forgetByTag(String tag) async {
    final keys = _tagToKeys[tag];
    if (keys != null) {
      // Remove all keys associated with this tag
      for (final key in keys) {
        // Remove tag from key's tag set
        _keyToTags[key]?.remove(tag);

        // If key has no more tags, remove it from key-to-tags mapping
        if (_keyToTags[key]?.isEmpty ?? false) {
          _keyToTags.remove(key);
          _tagTimestamps.remove(key);
        }
      }

      // Remove the tag entirely
      _tagToKeys.remove(tag);
    }
  }

  @override
  Set<String> getKeysForTag(String tag) {
    return Set.unmodifiable(_tagToKeys[tag] ?? {});
  }

  @override
  Set<String> getTagsForKey(String key) {
    return Set.unmodifiable(_keyToTags[key] ?? {});
  }

  @override
  void removeTagsForKey(String key) {
    final tags = _keyToTags[key];
    if (tags != null) {
      // Remove key from all tag mappings
      for (final tag in tags) {
        _tagToKeys[tag]?.remove(key);

        // If tag has no more keys, remove it
        if (_tagToKeys[tag]?.isEmpty ?? false) {
          _tagToKeys.remove(tag);
        }
      }

      // Remove key from mappings
      _keyToTags.remove(key);
      _tagTimestamps.remove(key);
    }
  }

  @override
  Set<String> getAllTags() {
    return Set.unmodifiable(_tagToKeys.keys);
  }

  @override
  void clearAllTags() {
    _tagToKeys.clear();
    _keyToTags.clear();
    _tagTimestamps.clear();
  }

  /// Gets the timestamp when a key was last tagged.
  DateTime? getKeyTagTimestamp(String key) {
    return _tagTimestamps[key];
  }

  /// Checks if a key has any tags.
  bool hasTags(String key) {
    return _keyToTags.containsKey(key) && (_keyToTags[key]?.isNotEmpty ?? false);
  }

  /// Gets all keys that have tags.
  Set<String> getAllTaggedKeys() {
    return Set.unmodifiable(_keyToTags.keys);
  }
}