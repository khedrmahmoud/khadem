import '../../../contracts/cache/cache_validator.dart';
import '../../../support/exceptions/cache_exceptions.dart';

/// Implementation of cache validator.
/// Handles input validation and business rules for cache operations.
class CacheValidator implements ICacheValidator {
  @override
  void validateKey(String key) {
    if (key.isEmpty) {
      throw CacheException('Cache key cannot be empty');
    }

    // Check for potentially problematic characters
    if (key.contains('\x00')) {
      throw CacheException('Cache key cannot contain null characters');
    }

    // Check key length (reasonable limit to prevent issues)
    if (key.length > 250) {
      throw CacheException('Cache key is too long (maximum 250 characters)');
    }
  }

  @override
  void validateTtl(Duration ttl) {
    if (ttl.isNegative) {
      throw CacheException('TTL duration cannot be negative');
    }

    // Check for unreasonably long TTL
    const maxTtl = Duration(days: 365 * 10); // 10 years
    if (ttl > maxTtl) {
      throw CacheException('TTL duration is too long (maximum 10 years)');
    }
  }

  @override
  void validateDriverName(String name) {
    if (name.isEmpty) {
      throw CacheException('Cache driver name cannot be empty');
    }

    // Check for valid characters in driver name
    final validNameRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
    if (!validNameRegex.hasMatch(name)) {
      throw CacheException(
        'Cache driver name must start with a letter and contain only letters, numbers, hyphens, and underscores',
      );
    }
  }

  @override
  void validateTags(List<String> tags) {
    if (tags.isEmpty) {
      throw CacheException('At least one tag must be provided');
    }

    for (final tag in tags) {
      if (tag.isEmpty) {
        throw CacheException('Cache tag cannot be empty');
      }

      if (tag.contains('\x00')) {
        throw CacheException('Cache tag cannot contain null characters');
      }

      if (tag.length > 50) {
        throw CacheException('Cache tag is too long (maximum 50 characters)');
      }
    }

    // Check for duplicate tags
    if (tags.length != tags.toSet().length) {
      throw CacheException('Duplicate tags are not allowed');
    }
  }

  /// Validates cache value size.
  void validateValueSize(dynamic value, {int maxSize = 10 * 1024 * 1024}) {
    // For simple validation, we can check string length or basic object size
    // More sophisticated size checking could be implemented if needed
    if (value is String && value.length > maxSize) {
      throw CacheException('Cache value is too large (maximum $maxSize characters for strings)');
    }
  }

  /// Validates configuration map structure.
  void validateConfigStructure(Map<String, dynamic> config) {
    // Validate basic structure
    if (config.containsKey('drivers') && config['drivers'] is! Map) {
      throw CacheException('Cache drivers configuration must be a map');
    }

    if (config.containsKey('default') && config['default'] is! String) {
      throw CacheException('Cache default driver must be a string');
    }
  }
}