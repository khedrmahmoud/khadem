import '../../../contracts/database/connection_interface.dart';
import '../../../contracts/session/session_interfaces.dart';

/// Database-based session storage implementation.
/// Stores session data in a database table for persistence and scalability.
class DatabaseSessionDriver implements SessionDriver {
  final ConnectionInterface _connection;
  final String _tableName;

  DatabaseSessionDriver(
    this._connection, {
    String tableName = 'sessions',
  }) : _tableName = tableName;

  @override
  Future<void> write(String sessionId, Map<String, dynamic> data) async {
    final payload = data.toString(); // Simplified - should use proper JSON encoding

    await _connection.execute('''
      INSERT INTO $_tableName (session_id, payload, last_activity)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE
        payload = VALUES(payload),
        last_activity = VALUES(last_activity)
    ''', [
      sessionId,
      payload,
      data['last_activity'] ?? DateTime.now().toIso8601String(),
    ]);
  }

  @override
  Future<Map<String, dynamic>?> read(String sessionId) async {
    final response = await _connection.execute(
      'SELECT payload FROM $_tableName WHERE session_id = ?',
      [sessionId],
    );

    if (response.data == null || (response.data is List && response.data.isEmpty)) {
      return null;
    }

    try {
      final rows = response.data is List ? response.data as List : [response.data];
      final payload = rows.first['payload'] as String;
      // Simplified parsing - in production use proper JSON deserialization
      if (payload.startsWith('{') && payload.endsWith('}')) {
        final Map<String, dynamic> data = {};
        final pairs = payload.substring(1, payload.length - 1).split(', ');
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
    await _connection.execute(
      'DELETE FROM $_tableName WHERE session_id = ?',
      [sessionId],
    );
  }

  @override
  Future<void> cleanup(Duration maxAge) async {
    final cutoffTime = DateTime.now().subtract(maxAge);

    await _connection.execute('''
      DELETE FROM $_tableName
      WHERE last_activity < ?
    ''', [cutoffTime.toIso8601String()],
    );
  }

  @override
  Future<bool> isConnected() async {
    return _connection.isConnected && await _connection.ping();
  }

  /// Create the sessions table if it doesn't exist
  Future<void> createTable() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        session_id VARCHAR(255) PRIMARY KEY,
        payload TEXT NOT NULL,
        last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }
}