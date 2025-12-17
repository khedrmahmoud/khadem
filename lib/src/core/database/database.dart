import '../../contracts/config/config_contract.dart';
import '../../contracts/database/database_connection.dart';
import '../../contracts/database/query_builder_interface.dart';
import '../../contracts/database/schema_builder.dart';
import '../../support/exceptions/database_exception.dart';
import 'database_drivers/mysql/mysql_connection.dart';

/// Manages the active database connection and builder.
class DatabaseManager {
  final ConfigInterface _config;
  final Map<String, DatabaseConnection> _connections = {};

  DatabaseManager(this._config);

  /// Initializes the default connection.
  Future<String> init() async {
    final defaultName = _config.get('database.default', 'mysql')!;
    // Ensure default connection is created and connected
    await connection(defaultName).connect();
    return defaultName;
  }

  /// Gets a query builder for the given table.
  QueryBuilderInterface<T> table<T>(
    String tableName, {
    T Function(Map<String, dynamic>)? modelFactory,
    String? connectionName,
  }) {
    return connection(connectionName)
        .queryBuilder<T>(tableName, modelFactory: modelFactory);
  }

  /// Gets the current connection.
  DatabaseConnection connection([String? name]) {
    name ??= _config.get('database.default', 'mysql');

    if (!_connections.containsKey(name)) {
      _connections[name!] = _resolveConnection(name);
    }

    return _connections[name]!;
  }

  DatabaseConnection _resolveConnection(String name) {
    var config =
        _config.get<Map<String, dynamic>>('database.connections.' + name);

    // Fallback for legacy single-connection config
    if (config == null && name == _config.get('database.default', 'mysql')) {
      config = _config.section('database');
      if (config != null && config.containsKey('connections')) {
        config = null;
      }
    }

    if (config == null) {
      throw DatabaseException(
          'Database connection [' + name + '] not configured',);
    }

    final driver = config['driver'] as String?;
    if (driver == null) {
      throw DatabaseException(
          'Driver not specified for connection [' + name + ']',);
    }

    switch (driver) {
      case 'mysql':
        return MySQLConnection(config);
      default:
        throw DatabaseException('Unsupported database driver: $driver');
    }
  }

  /// Gets the current schema builder (for default connection).
  SchemaBuilder get schemaBuilder {
    return connection().getSchemaBuilder();
  }

  /// Closes all active connections.
  Future<void> close() async {
    for (final conn in _connections.values) {
      await conn.disconnect();
    }
    _connections.clear();
  }
}
