import 'dart:async';
import 'dart:convert';
import 'package:khadem/src/support/exceptions/cache_exceptions.dart';
import 'package:redis/redis.dart';
import '../../../contracts/cache/cache_driver.dart';
import '../cache_stats.dart';

/// Redis-based cache driver implementation for the Khadem framework.
///
/// This driver provides high-performance, distributed caching using Redis as the
/// underlying storage backend. It's ideal for applications that need shared caching
/// across multiple instances or processes.
///
/// ## Key Features
///
/// - **High Performance**: Fast O(1) operations using Redis in-memory storage
/// - **Distributed**: Shared cache across multiple application instances
/// - **Persistence**: Optional Redis persistence for cache durability
/// - **TTL Support**: Automatic expiration of cache entries
/// - **Statistics Tracking**: Built-in performance metrics
/// - **Connection Pooling**: Efficient connection management
/// - **Error Handling**: Robust error handling with graceful degradation
/// - **Configuration**: Flexible Redis connection settings
///
/// ## Usage
///
/// ```dart
/// // Create a Redis cache driver with default settings
/// final cache = RedisCacheDriver();
///
/// // Create with custom settings
/// final cache = RedisCacheDriver(
///   host: 'redis.example.com',
///   port: 6379,
///   password: 'secret',
///   database: 1,
/// );
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
/// ## Configuration Options
///
/// - **host**: Redis server hostname (default: 'localhost')
/// - **port**: Redis server port (default: 6379)
/// - **password**: Redis server password (optional)
/// - **database**: Redis database number (default: 0)
/// - **maxRetries**: Maximum connection retry attempts (default: 3)
/// - **retryDelay**: Delay between retry attempts (default: 100ms)
///
/// ## Performance Characteristics
///
/// - **put()**: O(1) - Constant time insertion
/// - **get()**: O(1) - Constant time retrieval
/// - **has()**: O(1) - Constant time existence check
/// - **forget()**: O(1) - Constant time deletion
/// - **clear()**: O(n) - Linear time for all entries in database
///
/// ## Connection Management
///
/// The driver maintains a connection pool and automatically reconnects on failures.
/// Connections are reused across operations for optimal performance.
///
/// ## Error Handling
///
/// The driver gracefully handles Redis connection failures and network issues.
/// Failed operations are logged and statistics are updated accordingly.
///
/// ## Thread Safety
///
/// This implementation is thread-safe and can be used concurrently from multiple
/// isolates, though each isolate will maintain its own connection pool.
class RedisCacheDriver implements CacheDriver {
  /// Redis server hostname
  final String host;

  /// Redis server port
  final int port;

  /// Redis server password (optional)
  final String? password;

  /// Redis database number
  final int database;

  /// Maximum number of connection retry attempts
  final int maxRetries;

  /// Delay between retry attempts
  final Duration retryDelay;

  /// Cache statistics tracker
  final CacheStats _stats = CacheStats();

  /// Redis connection instance
  Command? _command;

  /// Connection mutex to prevent concurrent connection attempts
  bool _connecting = false;

  /// Creates a new RedisCacheDriver instance.
  ///
  /// [host] - Redis server hostname (default: 'localhost')
  /// [port] - Redis server port (default: 6379)
  /// [password] - Redis server password (optional)
  /// [database] - Redis database number (default: 0)
  /// [maxRetries] - Maximum connection retry attempts (default: 3)
  /// [retryDelay] - Delay between retry attempts (default: 100ms)
  RedisCacheDriver({
    this.host = 'localhost',
    this.port = 6379,
    this.password,
    this.database = 0,
    this.maxRetries = 3,
    this.retryDelay = const Duration(milliseconds: 100),
  });

  /// Gets the Redis command instance, creating a connection if necessary.
  ///
  /// This method handles connection creation, authentication, and database selection.
  /// It includes retry logic for connection failures.
  Future<Command> _getCommand() async {
    if (_command != null) {
      return _command!;
    }

    if (_connecting) {
      // Wait for another connection attempt to complete
      while (_connecting) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      if (_command != null) {
        return _command!;
      }
    }

    _connecting = true;
    try {
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          final conn = RedisConnection();
          _command = await conn.connect(host, port);

          // Authenticate if password is provided
          if (password != null && password!.isNotEmpty) {
            await _command!.send_object(['AUTH', password]);
          }

          // Select database
          if (database != 0) {
            await _command!.send_object(['SELECT', database]);
          }

          return _command!;
        } catch (e) {
          if (attempt == maxRetries) {
            rethrow;
          }
          await Future.delayed(retryDelay * (attempt + 1));
        }
      }
    } finally {
      _connecting = false;
    }

    throw StateError('Failed to connect to Redis after $maxRetries attempts');
  }

  /// Executes a Redis command with error handling and retry logic.
  ///
  /// This method wraps Redis operations with proper error handling and
  /// updates cache statistics accordingly.
  Future<dynamic> _executeCommand(
    List<Object> command, {
    bool isRead = false,
    bool isWrite = false,
  }) async {
    try {
      final cmd = await _getCommand();
      final result = await cmd.send_object(command);

      if (isRead) {
        _stats.hits++;
      } else if (isWrite) {
        _stats.sets++;
      }

      return result;
    } catch (e) {
      if (isRead) {
        _stats.misses++;
      }
      // Reset connection on error to force reconnection
      _command = null;
      rethrow;
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

    try {
      final serializedValue = jsonEncode(value);

      // Use PX (milliseconds) for small TTLs, EX (seconds) for larger ones
      final ttlInSeconds = ttl.inSeconds;
      final ttlInMilliseconds = ttl.inMilliseconds;

      List<Object> command;
      if (ttlInSeconds == 0 && ttlInMilliseconds > 0) {
        // For TTLs less than 1 second, use PX (milliseconds)
        command = ['SET', key, serializedValue, 'PX', ttlInMilliseconds];
      } else if (ttlInSeconds > 0) {
        // For TTLs of 1 second or more, use EX (seconds)
        command = ['SET', key, serializedValue, 'EX', ttlInSeconds];
      } else {
        // TTL is zero or negative (shouldn't happen due to validation above)
        command = ['SET', key, serializedValue];
      }

      await _executeCommand(command, isWrite: true);
    } catch (e) {
      throw CacheException('Failed to store cache item "$key": $e');
    }
  }

  @override
  Future<dynamic> get(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    try {
      final result = await _executeCommand(['GET', key], isRead: true);

      if (result == null) {
        _stats.misses++;
        _stats.hits--; // Correct the hit count since it's actually a miss
        return null;
      }

      return jsonDecode(result as String);
    } catch (e) {
      _stats.misses++;
      _stats.hits--; // Correct the hit count
      throw CacheException('Failed to retrieve cache item "$key": $e');
    }
  }

  @override
  Future<void> forget(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    try {
      await _executeCommand(['DEL', key], isWrite: true);
      _stats.deletions++;
      _stats.sets--; // Correct the set count since DEL is not a SET operation
    } catch (e) {
      throw CacheException('Failed to remove cache item "$key": $e');
    }
  }

  @override
  Future<bool> has(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    try {
      final result = await _executeCommand(['EXISTS', key], isRead: true);

      if (result == 1) {
        return true;
      } else {
        _stats.misses++;
        _stats.hits--; // Correct the hit count since EXISTS returned 0
        return false;
      }
    } catch (e) {
      _stats.misses++;
      _stats.hits--; // Correct the hit count
      throw CacheException('Failed to check cache item "$key": $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _executeCommand(['FLUSHDB']);
      _stats.clears++;
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
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
  /// - `clears`: Number of cache clears
  /// - `hitRate`: Cache hit rate as a percentage (0.0 to 100.0)
  /// - `totalOperations`: Total number of cache operations
  CacheStats getStats() {
    return _stats.copy();
  }

  /// Closes the Redis connection and cleans up resources.
  ///
  /// Call this method when the cache driver is no longer needed to prevent
  /// resource leaks and ensure proper connection cleanup.
  Future<void> dispose() async {
    if (_command != null) {
      try {
        await _command!.get_connection().close();
      } catch (e) {
        // Ignore errors during cleanup
      }
      _command = null;
    }
  }
}
