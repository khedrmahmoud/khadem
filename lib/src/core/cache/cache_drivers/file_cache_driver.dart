import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/contracts/cache/cache_driver.dart';
import '../cache_stats.dart';

/// A file-based cache driver implementation for the Khadem framework.
///
/// This driver stores cache data as JSON files on the local filesystem,
/// providing a persistent caching solution suitable for single-server applications
/// or development environments. Each cache entry is stored as a separate file
/// with metadata including expiration time and TTL information.
///
/// ## Key Features
///
/// - **Persistent Storage**: Cache data survives application restarts
/// - **TTL Support**: Automatic expiration of cache entries with cleanup
/// - **File Handle Management**: Proper cleanup with Windows compatibility
/// - **Key Sanitization**: Safe file naming for cache keys
/// - **Compression**: Optional gzip compression for large values (>1KB)
/// - **Statistics**: Built-in performance metrics with persistent storage
/// - **Error Handling**: Robust error handling with graceful degradation
/// - **Cross-Platform**: Optimized for both Unix and Windows file systems
/// - **Async Operations**: Non-blocking metadata persistence
///
/// ## Thread Safety
///
/// This implementation is not thread-safe for concurrent access to the same cache directory.
/// Dart isolates do not share memory, and file locks are not implemented in this driver.
/// Concurrent access from multiple isolates or processes is not safe.
/// For multi-threaded applications, use different cache directories or implement
/// external synchronization mechanisms.
///
/// ## Usage
///
/// ```dart
/// // Create a file cache driver with default settings
/// final cache = FileCacheDriver();
///
/// // Create with custom directory
/// final cache = FileCacheDriver(cacheDir: '/tmp/my_cache');
///
/// // Create with custom settings
/// final cache = FileCacheDriver(
///   cacheDir: '/var/cache/myapp',
///   maxFileSize: 50 * 1024 * 1024, // 50MB
///   compressionThreshold: 2048, // 2KB
///   enableCompression: true,
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
/// ## Configuration
///
/// The driver accepts the following configuration options:
/// - `cacheDir`: Directory path for cache storage (default: 'storage/cache')
/// - `maxFileSize`: Maximum file size in bytes (default: 10MB)
/// - `compressionThreshold`: Size threshold for compression (default: 1KB)
/// - `enableCompression`: Whether to enable gzip compression (default: true)
/// - `filePermissions`: File permissions for cache files (default: 0644)
///
/// ## Performance Considerations
///
/// - File I/O operations are generally slower than memory-based caches
/// - Suitable for caching large objects or data that needs persistence
/// - Consider using memory cache for frequently accessed small data
/// - Monitor disk space usage as cache files accumulate
/// - Windows file handle management includes delays to prevent access conflicts
/// - Statistics are persisted asynchronously to avoid blocking operations
///
/// ## Error Handling
///
/// The driver handles various error conditions:
/// - Invalid cache directory paths
/// - File system permission issues
/// - Disk space exhaustion
/// - Corrupted cache files (automatic cleanup)
/// - Concurrent access conflicts
/// - Windows file handle locking (with retry mechanisms)
/// - Compression/decompression failures
/// - Metadata persistence failures (graceful degradation)
class FileCacheDriver implements CacheDriver {
  /// The cache directory path
  final String _cacheDir;

  /// Maximum file size in bytes (default: 10MB)
  final int _maxFileSize;

  /// Size threshold for compression in bytes (default: 1KB)
  final int _compressionThreshold;

  /// Whether to enable gzip compression
  final bool _enableCompression;

  /// File permissions for cache files
  final int _filePermissions;

  /// Cache statistics
  final CacheStats _stats = CacheStats();

  /// File extension for cache files
  static const String _fileExtension = '.cache.json';

  /// Metadata file for cache statistics
  static const String _metadataFile = '.cache_metadata.json';

  /// Lock file used to serialize clear operations.
  static const String _clearLockFile = '.clear.lock';

  static const Duration _clearLockMaxAge = Duration(seconds: 30);

  /// Creates a new FileCacheDriver instance.
  ///
  /// [cacheDir] - The directory path where cache files will be stored.
  ///              The directory will be created if it doesn't exist.
  ///              (default: 'storage/cache')
  /// [maxFileSize] - Maximum size of individual cache files in bytes (default: 10MB)
  /// [compressionThreshold] - Size threshold for enabling compression (default: 1KB)
  /// [enableCompression] - Whether to enable gzip compression (default: true)
  /// [filePermissions] - File permissions for cache files (default: 0644)
  ///
  /// Throws [ArgumentError] if [cacheDir] is empty or null.
  /// Throws [FileSystemException] if the cache directory cannot be created or is not writable.
  FileCacheDriver({
    String cacheDir = 'storage/cache',
    int maxFileSize = 10 * 1024 * 1024, // 10MB
    int compressionThreshold = 1024, // 1KB
    bool enableCompression = true,
    int filePermissions = 0x644, // rw-r--r--
  }) : _cacheDir = cacheDir.trim(),
       _maxFileSize = maxFileSize,
       _compressionThreshold = compressionThreshold,
       _enableCompression = enableCompression,
       _filePermissions = filePermissions {
    if (_cacheDir.isEmpty) {
      throw ArgumentError('Cache directory path cannot be empty');
    }

    // Create cache directory if it doesn't exist
    _ensureCacheDirectory();

    // Load existing metadata if available
    _loadMetadata();
  }

  /// Ensures the cache directory exists and is writable.
  void _ensureCacheDirectory() {
    final dir = Directory(_cacheDir);

    try {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Verify directory is writable
      final testFile = File('$_cacheDir/.write_test');
      testFile.writeAsStringSync('test');
      testFile.deleteSync();
    } catch (e) {
      throw FileSystemException(
        'Cannot create or write to cache directory: $_cacheDir',
        _cacheDir,
      );
    }
  }

  /// Loads cache metadata from disk.
  void _loadMetadata() {
    final metadataPath = '$_cacheDir/$_metadataFile';
    final file = File(metadataPath);

    if (file.existsSync()) {
      try {
        final data = jsonDecode(file.readAsStringSync());
        final loadedStats = CacheStats.fromJson(data);
        _stats.hits = loadedStats.hits;
        _stats.misses = loadedStats.misses;
        _stats.sets = loadedStats.sets;
        _stats.deletions = loadedStats.deletions;
        _stats.expirations = loadedStats.expirations;
        _stats.clears = loadedStats.clears;
      } catch (e) {
        // If metadata is corrupted, start fresh
        _stats.reset();
      }
    }
  }

  /// Saves cache metadata to disk asynchronously.
  ///
  /// This method runs in the background to avoid blocking cache operations.
  /// If metadata cannot be saved, the operation fails silently to prevent
  /// cache functionality from being disrupted.
  Future<void> _saveMetadata() async {
    final metadataPath = '$_cacheDir/$_metadataFile';
    final file = File(metadataPath);

    try {
      final data = _stats.toJson();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Silently fail if we can't save metadata
    }
  }

  /// Sanitizes cache key for safe file naming.
  ///
  /// Uses deterministic encoding to avoid directory traversal and
  /// platform-dependent filename issues.
  String _sanitizeKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    if (normalizedKey.length > 2048) {
      throw ArgumentError('Cache key exceeds maximum supported length');
    }

    final encoded = base64UrlEncode(
      utf8.encode(normalizedKey),
    ).replaceAll('=', '');

    // Keep filenames manageable on Windows and Linux filesystems.
    if (encoded.length <= 180) {
      return encoded;
    }

    return '${encoded.substring(0, 160)}_${_fnv1a64Hex(normalizedKey)}';
  }

  String _fnv1a64Hex(String input) {
    const int offsetBasis = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    const int mask64 = 0xFFFFFFFFFFFFFFFF;

    var hash = offsetBasis;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * prime) & mask64;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Gets the full file path for a cache key.
  String _getFilePath(String key) {
    final sanitizedKey = _sanitizeKey(key);
    return '$_cacheDir/$sanitizedKey$_fileExtension';
  }

  @override
  Future<bool> add(String key, dynamic value, Duration ttl) async {
    if (await has(key)) {
      return false;
    }
    await put(key, value, ttl);
    return true;
  }

  @override
  Future<Map<String, dynamic>> many(List<String> keys) async {
    final Map<String, dynamic> results = {};
    for (final key in keys) {
      final value = await get(key);
      if (value != null) {
        results[key] = value;
      }
    }
    return results;
  }

  @override
  Future<void> putMany(Map<String, dynamic> values, Duration ttl) async {
    for (final entry in values.entries) {
      await put(entry.key, entry.value, ttl);
    }
  }

  @override
  Future<int> increment(String key, [int amount = 1]) async {
    final value = await get(key);
    final int currentValue = (value is int)
        ? value
        : int.tryParse(value.toString()) ?? 0;
    final newValue = currentValue + amount;
    await put(key, newValue, const Duration(days: 365 * 100));
    return newValue;
  }

  @override
  Future<int> decrement(String key, [int amount = 1]) async {
    return increment(key, -amount);
  }

  @override
  Future<dynamic> pull(String key) async {
    final value = await get(key);
    if (value != null) {
      await forget(key);
    }
    return value;
  }

  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    if (ttl.isNegative) {
      throw ArgumentError('TTL duration cannot be negative');
    }

    final filePath = _getFilePath(key);

    // Prepare cache data with metadata
    final now = DateTime.now();
    final expiresAt = now.add(ttl);
    final data = {
      'value': value,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': now.toIso8601String(),
      'ttl_seconds': ttl.inSeconds,
      'compressed': false,
    };

    // Encode data to JSON
    var encodedData = jsonEncode(data);

    // Apply compression if enabled and beneficial
    if (_enableCompression && encodedData.length > _compressionThreshold) {
      final compressedBytes = gzip.encode(utf8.encode(encodedData));
      if (compressedBytes.length < encodedData.length) {
        encodedData = base64Encode(compressedBytes);
        data['compressed'] = true;
      }
    }

    // Check file size limit
    if (encodedData.length > _maxFileSize) {
      throw FileSystemException(
        'Cache data size (${encodedData.length} bytes) exceeds maximum file size ($_maxFileSize bytes)',
        filePath,
      );
    }

    // Write to file using IOSink for better Windows compatibility
    final file = File(filePath);
    final sink = file.openWrite();
    sink.write(encodedData);
    await sink.close();

    // Set file permissions only on Unix-like platforms.
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', [
          '${_filePermissions.toRadixString(8)}',
          filePath,
        ]);
      } catch (e) {
        // Silently fail if chmod is not available.
      }
    }

    // Update statistics and persist metadata
    _stats.sets++;
    await _saveMetadata();
  }

  @override
  Future<dynamic> get(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    final filePath = _getFilePath(key);
    final file = File(filePath);

    if (!await file.exists()) {
      _stats.misses++;
      await _saveMetadata();
      return null;
    }

    try {
      var encodedData = await file.readAsString();
      final isCompressed = encodedData.startsWith(
        'H4sI',
      ); // Gzip magic bytes in base64

      Map<String, dynamic> data;

      if (isCompressed) {
        // Decompress the data
        try {
          final compressedBytes = base64Decode(encodedData);
          final decompressedBytes = gzip.decode(compressedBytes);
          encodedData = utf8.decode(decompressedBytes);
          data = jsonDecode(encodedData);
        } catch (e) {
          // If decompression fails, treat as corrupted
          throw const FormatException('Failed to decompress cache data');
        }
      } else {
        data = jsonDecode(encodedData);
      }

      final expiresAt = DateTime.parse(data['expires_at']);
      final now = DateTime.now();

      if (now.isAfter(expiresAt)) {
        // Cache expired, remove file
        await forget(key);
        _stats.misses++;
        _stats.expirations++;
        await _saveMetadata();
        return null;
      }

      // Update statistics
      _stats.hits++;
      await _saveMetadata();

      // Return the value
      return data['value'];
    } catch (e) {
      // If file is corrupted, remove it
      try {
        await file.delete();
      } catch (_) {
        // Ignore deletion errors
      }
      _stats.misses++;
      await _saveMetadata();
      return null;
    }
  }

  @override
  Future<void> forget(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Cache key cannot be empty');
    }

    final filePath = _getFilePath(key);
    final file = File(filePath);

    if (!await file.exists()) {
      return; // Already doesn't exist
    }

    // On Windows, file handles may not be released immediately after file operations.
    // Add a small delay to allow file handles to be released and prevent access conflicts.
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await file.delete();
      _stats.deletions++;
      await _saveMetadata();
    } catch (e) {
      // If deletion fails (e.g., due to file locking), just continue
      // This can happen if the file is locked by another process
    }
  }

  @override
  Future<bool> has(String key) async {
    return await get(key) != null;
  }

  @override
  Future<void> clear() async {
    final dir = Directory(_cacheDir);

    if (!await dir.exists()) {
      return;
    }

    final lockFile = await _acquireClearLock();
    try {
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.endsWith(_fileExtension) &&
            !entity.path.endsWith(_metadataFile)) {
          await _deleteFileBestEffort(entity);
        }
      }

      // Reset statistics
      _stats.reset();
      _stats.clears = 1;
      await _saveMetadata();
    } catch (e) {
      // If directory listing fails, try to recreate the directory
      try {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
        _stats.reset();
        _stats.clears = 1;
        await _saveMetadata();
      } catch (e) {
        // If all else fails, just reset stats
        _stats.reset();
      }
    } finally {
      try {
        if (await lockFile.exists()) {
          await lockFile.delete();
        }
      } catch (_) {
        // Ignore lock cleanup failures.
      }
    }
  }

  Future<File> _acquireClearLock() async {
    final lockFile = File('$_cacheDir/$_clearLockFile');

    if (await lockFile.exists()) {
      try {
        final age = DateTime.now().difference(await lockFile.lastModified());
        if (age <= _clearLockMaxAge) {
          throw StateError('Clear operation already in progress');
        }
      } catch (e) {
        if (e is StateError) {
          rethrow;
        }
      }

      try {
        await lockFile.delete();
      } catch (_) {
        throw StateError('Clear operation lock is stale but cannot be removed');
      }
    }

    await lockFile.create(recursive: true);
    await lockFile.writeAsString(DateTime.now().toIso8601String(), flush: true);

    return lockFile;
  }

  Future<void> _deleteFileBestEffort(File file) async {
    try {
      await file.delete();
      return;
    } catch (_) {
      // Retry once for transient file handle contention (common on Windows).
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        await file.delete();
      } catch (_) {
        // Ignore persistent deletion failures and continue clearing other files.
      }
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
  /// - `expirations`: Number of expired entries encountered
  /// - `clears`: Number of cache clears
  /// - `hitRate`: Cache hit rate as a percentage (0.0 to 100.0)
  /// - `totalOperations`: Total number of cache operations
  CacheStats getStats() {
    return _stats.copy();
  }

  /// Gets the cache directory path.
  String get cacheDirectory => _cacheDir;

  /// Gets the maximum file size limit.
  int get maxFileSize => _maxFileSize;

  /// Gets the compression threshold.
  int get compressionThreshold => _compressionThreshold;

  /// Checks if compression is enabled.
  bool get compressionEnabled => _enableCompression;
}
