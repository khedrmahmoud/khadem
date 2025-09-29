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
    final lastActivity = data['last_activity'] ?? DateTime.now().toIso8601String();

    final queryBuilder = _connection.queryBuilder<Map<String, dynamic>>(_tableName);

    // Check if session exists
    final exists = await queryBuilder
        .where('session_id', '=', sessionId)
        .exists();

    if (exists) {
      // Update existing session
      await queryBuilder
          .where('session_id', '=', sessionId)
          .update({
            'payload': payload,
            'last_activity': lastActivity,
          });
    } else {
      // Insert new session
      await queryBuilder.insert({
        'session_id': sessionId,
        'payload': payload,
        'last_activity': lastActivity,
      });
    }
  }

  @override
  Future<Map<String, dynamic>?> read(String sessionId) async {
    final queryBuilder = _connection.queryBuilder<Map<String, dynamic>>(_tableName);

    final result = await queryBuilder
        .select(['payload'])
        .where('session_id', '=', sessionId)
        .first();

    if (result == null) {
      return null;
    }

    try {
      final payload = result['payload'] as String;
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
    final queryBuilder = _connection.queryBuilder<Map<String, dynamic>>(_tableName);

    await queryBuilder
        .where('session_id', '=', sessionId)
        .delete();
  }

  @override
  Future<void> cleanup(Duration maxAge) async {
    final cutoffTime = DateTime.now().subtract(maxAge);
    final queryBuilder = _connection.queryBuilder<Map<String, dynamic>>(_tableName);

    await queryBuilder
        .where('last_activity', '<', cutoffTime.toIso8601String())
        .delete();
  }

  @override
  Future<bool> isConnected() async {
    return _connection.isConnected && await _connection.ping();
  }

  /// Create the sessions table if it doesn't exist
  /// Note: This uses raw SQL for simplicity. In the future, this could be
  /// updated to use the SchemaBuilder for better database abstraction.
  Future<void> createTable() async {
    // Use database-agnostic SQL that works across different database types
    final createTableSql = '''
      CREATE TABLE IF NOT EXISTS $_tableName (
        session_id VARCHAR(255) PRIMARY KEY,
        payload TEXT NOT NULL,
        last_activity TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''';

    await _connection.execute(createTableSql);
  }
}