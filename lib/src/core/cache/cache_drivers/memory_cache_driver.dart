import 'dart:async';
import 'package:khadem/src/contracts/cache/cache_driver.dart';

import '../cache_stats.dart';

/// An in-memory cache driver implementation for the Khadem framework.
///
/// This driver provides fast, volatile caching using a Dart Map as the underlying storage.
/// It's ideal for caching frequently accessed data that doesn't need to persist across
/// application restarts. The driver includes automatic TTL (time-to-live) expiration,
/// statistics tracking, and efficient memory management.
///
/// ## Key Features
///
/// - **High Performance**: Fast O(1) operations using HashMap
/// - **TTL Support**: Automatic expiration of cache entries
/// - **Statistics Tracking**: Built-in performance metrics
/// - **Memory Efficient**: Minimal memory overhead
/// - **Thread Safe**: Safe for concurrent access within a single isolate
/// - **Automatic Cleanup**: Background task removes expired entries
///
/// ## Usage
///
/// ```dart
/// // Create a memory cache driver
/// final cache = MemoryCacheDriver();
///
/// // Store data with TTL
/// await cache.put('user:123', {'name': 'John', 'email': 'john@example.com'}, Duration(hours: 1));
///
/// // Retrieve data
/// final user = await cache.get('user:123');
///
/// // Check if key exists
/// final exists = await cache.has('user:123');
///
/// // Remove specific key
/// await cache.forget('user:123');
///
/// // Clear all cache
/// await cache.clear();
///
/// // Get cache statistics
/// final stats = cache.getStats();
/// print('Hit rate: ${stats.hitRate}%');
/// ```
///
/// ## Performance Characteristics
///
/// - **put()**: O(1) - Constant time insertion
/// - **get()**: O(1) - Constant time retrieval
/// - **has()**: O(1) - Constant time existence check
/// - **forget()**: O(1) - Constant time deletion
/// - **clear()**: O(n) - Linear time for all entries
///
/// ## Memory Management
///
/// The driver uses Dart's built-in garbage collection for memory management.
/// Cache entries are automatically cleaned up when they expire or are explicitly removed.
/// No manual memory management is required.
///
/// ## Thread Safety
///
/// This implementation is thread-safe within a single Dart isolate. However, since
/// Dart isolates do not share memory, each isolate would have its own cache instance.
/// For cross-isolate caching, consider using the file-based cache driver with
/// external synchronization.
///
/// ## Limitations
///
/// - **Volatility**: Data is lost when the application restarts
/// - **Memory Bound**: Limited by available RAM
/// - **No Persistence**: Cannot survive application crashes
/// - **Isolate Scoped**: Not shared between Dart isolates
class MemoryCacheDriver implements CacheDriver {
  /// Internal storage map for cache entries
  final Map<String, _CacheEntry> _store = {};

  /// Cache statistics tracker
  final CacheStats _stats = CacheStats();

  /// Timer for periodic cleanup of expired entries
  Timer? _cleanupTimer;

  /// Cleanup interval in seconds
  static const int _cleanupIntervalSeconds = 60; // 1 minute

  /// Creates a new MemoryCacheDriver instance.
  ///
  /// Starts a background cleanup timer that runs every minute to remove expired entries.
  /// The timer helps prevent memory leaks from expired entries that haven't been accessed.
  MemoryCacheDriver() {
    _startCleanupTimer();
  }

  /// Starts the periodic cleanup timer.
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: _cleanupIntervalSeconds),
      (_) => _cleanupExpiredEntries(),
    );
  }

  /// Cleans up expired entries from the cache.
  ///
  /// This method is called periodically by the cleanup timer and also
  /// during individual operations to ensure expired entries are removed.
  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _store.forEach((key, entry) {
      if (entry.isExpired(now)) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _store.remove(key);
      _stats.expirations++;
    }
  }

  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    if (ttl.isNegative) {
      throw ArgumentError('TTL duration cannot be negative');
    }

    final entry = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
      ttl: ttl,
    );

    _store[key] = entry;
    _stats.sets++;

    // Clean up expired entries during put operations
    _cleanupExpiredEntries();
  }

  @override
  Future<dynamic> get(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    final entry = _store[key];

    if (entry == null) {
      _stats.misses++;
      return null;
    }

    if (entry.isExpired()) {
      _store.remove(key);
      _stats.misses++;
      _stats.expirations++;
      return null;
    }

    _stats.hits++;
    return entry.value;
  }

  @override
  Future<void> forget(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    if (_store.remove(key) != null) {
      _stats.deletions++;
    }
  }

  @override
  Future<bool> has(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    final entry = _store[key];

    if (entry == null) {
      _stats.misses++;
      return false;
    }

    if (entry.isExpired()) {
      _store.remove(key);
      _stats.misses++;
      _stats.expirations++;
      return false;
    }

    _stats.hits++;
    return true;
  }

  @override
  Future<void> clear() async {
    _store.clear();
    _stats.clears++;
    _stats.reset(); // Reset all stats when clearing
  }

  /// Gets cache statistics.
  ///
  /// Returns a statistics object containing various cache performance metrics.
  /// Statistics are tracked in real-time and provide insights into cache usage.
  ///
  /// Returns:
  /// - `hits`: Number of successful cache retrievals
  /// - `misses`: Number of cache misses
  /// - `sets`: Number of cache writes
  /// - `deletions`: Number of cache deletions
  /// - `expirations`: Number of expired entries encountered
  /// - `hitRate`: Cache hit rate as a percentage (0.0 to 100.0)
  /// - `totalOperations`: Total number of cache operations
  CacheStats getStats() {
    return _stats.copy();
  }

  /// Gets the current number of items in the cache.
  int get itemCount => _store.length;

  /// Disposes of the cache driver and cleans up resources.
  ///
  /// Cancels the cleanup timer and clears all cache entries.
  /// Call this method when the cache driver is no longer needed to prevent
  /// memory leaks from the periodic timer.
  void dispose() {
    _cleanupTimer?.cancel();
    _store.clear();
  }
}

/// Internal class representing a cache entry with expiration information.
class _CacheEntry {
  /// The cached value
  final dynamic value;

  /// When this entry expires
  final DateTime expiresAt;

  /// The original TTL duration
  final Duration ttl;

  /// Creates a new cache entry.
  _CacheEntry({
    required this.value,
    required this.expiresAt,
    required this.ttl,
  });

  /// Checks if this entry has expired.
  bool isExpired([DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    return currentTime.isAfter(expiresAt);
  }

  /// Gets the remaining TTL for this entry.
  Duration get remainingTtl {
    final now = DateTime.now();
    if (isExpired(now)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }
}
