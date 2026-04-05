import '../../contracts/config/config_contract.dart';
import '../../contracts/database/database_connection.dart';
import '../../contracts/database/query_builder_interface.dart';
import '../../contracts/database/schema_builder.dart';
import '../../support/exceptions/database_exception.dart';
import 'database_drivers/mysql/mysql_connection.dart';
import 'database_drivers/sqlite/sqlite_connection.dart';

/// Manages the active database connection and builder.
class DatabaseManager {
  final ConfigInterface _config;
  final Map<String, DatabaseConnection> _connections = {};
  final Map<String, List<DatabaseConnection>> _pools = {};
  final Map<String, int> _poolIndexes = {};

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
    return connection(
      connectionName,
    ).queryBuilder<T>(tableName, modelFactory: modelFactory);
  }

  /// Gets the current connection.
  DatabaseConnection connection([String? name]) {
    final connectionName = name ?? _config.get('database.default', 'mysql')!;

    if (!_pools.containsKey(connectionName)) {
      _initializePool(connectionName);
    }

    final pool = _pools[connectionName]!;
    if (pool.length == 1) {
      return pool.first;
    }

    final currentIndex = _poolIndexes[connectionName] ?? 0;
    final selected = pool[currentIndex % pool.length];
    _poolIndexes[connectionName] = (currentIndex + 1) % pool.length;
    return selected;
  }

  void _initializePool(String name) {
    final config = _resolveConnectionConfig(name);
    final poolSize = _resolvePoolSize(config);

    final pool = List<DatabaseConnection>.generate(
      poolSize,
      (_) => _buildConnection(config),
    );

    _pools[name] = pool;
    _connections[name] = pool.first;
    _poolIndexes[name] = 0;
  }

  int _resolvePoolSize(Map<String, dynamic> config) {
    final configured = config['pool_size'] ?? config['poolSize'];

    if (configured is int && configured > 0) {
      return configured;
    }

    if (configured is String) {
      final parsed = int.tryParse(configured);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return 1;
  }

  Map<String, dynamic> _resolveConnectionConfig(String name) {
    var config = _config.get<Map<String, dynamic>>(
      'database.connections.' + name,
    );

    // Fallback for legacy single-connection config
    if (config == null && name == _config.get('database.default', 'mysql')) {
      config = _config.section('database');
      if (config != null && config.containsKey('connections')) {
        config = null;
      }
    }

    if (config == null) {
      throw DatabaseException(
        'Database connection [' + name + '] not configured',
      );
    }

    return config;
  }

  DatabaseConnection _buildConnection(Map<String, dynamic> config) {
    final normalizedConfig = Map<String, dynamic>.from(config);

    final driver = normalizedConfig['driver'] as String?;
    if (driver == null) {
      throw DatabaseException('Driver not specified for database connection');
    }

    switch (driver) {
      case 'mysql':
        return MySQLConnection(normalizedConfig);
      case 'sqlite':
        return SQLiteConnection(normalizedConfig);
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
    final disconnected = <DatabaseConnection>{};

    for (final pool in _pools.values) {
      for (final conn in pool) {
        if (disconnected.add(conn)) {
          await conn.disconnect();
        }
      }
    }

    for (final conn in _connections.values) {
      if (disconnected.add(conn)) {
        await conn.disconnect();
      }
    }

    _pools.clear();
    _poolIndexes.clear();
    _connections.clear();
  }
}
