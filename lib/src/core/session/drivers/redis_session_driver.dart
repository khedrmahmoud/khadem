import 'package:redis/redis.dart';
import '../../../contracts/session/session_interfaces.dart';

/// Redis-based session storage implementation.
/// Stores session data in Redis for distributed caching.
class RedisSessionDriver implements SessionDriver {
  final RedisConnection _connection;
  late final Command _command;
  bool _isConnected = false;

  RedisSessionDriver({
    required String host,
    int port = 6379,
    String? password,
    int db = 0,
  }) : _connection = RedisConnection() {
    _initConnection(host, port, password, db);
  }

  Future<void> _initConnection(
      String host, int port, String? password, int db,) async {
    try {
      _command = await _connection.connect(host, port);
      if (password != null) {
        await _command.send_object(['AUTH', password]);
      }
      await _command.send_object(['SELECT', db]);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  @override
  Future<void> write(String sessionId, Map<String, dynamic> data) async {
    if (!_isConnected) {
      throw StateError('Redis connection not available');
    }

    final key = 'session:$sessionId';
    final jsonData = data.toString(); // Convert to JSON-like string

    // Store with TTL based on last activity
    final lastActivityStr = data['last_activity'] as String?;
    if (lastActivityStr != null) {
      try {
        final lastActivity = DateTime.parse(lastActivityStr);
        const ttl = Duration(hours: 24); // Default 24 hours
        final expiry = lastActivity.add(ttl);
        final ttlSeconds = expiry.difference(DateTime.now()).inSeconds;

        if (ttlSeconds > 0) {
          await _command.send_object(['SETEX', key, ttlSeconds, jsonData]);
          return;
        }
      } catch (e) {
        // Fall back to regular SET
      }
    }

    await _command.send_object(['SET', key, jsonData]);
  }

  @override
  Future<Map<String, dynamic>?> read(String sessionId) async {
    if (!_isConnected) {
      throw StateError('Redis connection not available');
    }

    final key = 'session:$sessionId';
    final result = await _command.send_object(['GET', key]);

    if (result == null) {
      return null;
    }

    try {
      // Parse the stored data (assuming it's stored as a string representation)
      final dataStr = result.toString();
      // For simplicity, we'll assume the data is stored as a JSON string
      // In a real implementation, you'd want proper JSON serialization
      if (dataStr.startsWith('{') && dataStr.endsWith('}')) {
        // This is a simplified parsing - in production you'd use proper JSON
        final Map<String, dynamic> data = {};
        // Parse key-value pairs (simplified implementation)
        final pairs = dataStr.substring(1, dataStr.length - 1).split(', ');
        for (final pair in pairs) {
          final parts = pair.split(': ');
          if (parts.length == 2) {
            final key = parts[0].replaceAll("'", '').replaceAll('"', '');
            final value = parts[1].replaceAll("'", '').replaceAll('"', '');
            data[key] = value;
          }
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> delete(String sessionId) async {
    if (!_isConnected) {
      throw StateError('Redis connection not available');
    }

    final key = 'session:$sessionId';
    await _command.send_object(['DEL', key]);
  }

  @override
  Future<void> cleanup(Duration maxAge) async {
    if (!_isConnected) {
      throw StateError('Redis connection not available');
    }

    // Redis handles TTL automatically, but we can clean up expired keys
    // This is a no-op since Redis handles expiration automatically
    // In a real implementation, you might want to scan for expired keys
  }

  @override
  Future<bool> isConnected() async {
    if (!_isConnected) {
      return false;
    }

    try {
      await _command.send_object(['PING']);
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Close the Redis connection
  Future<void> close() async {
    await _connection.close();
    _isConnected = false;
  }
}
