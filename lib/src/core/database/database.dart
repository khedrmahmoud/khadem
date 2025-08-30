
import '../../contracts/config/config_contract.dart';
import '../../contracts/database/connection_interface.dart';
import '../../contracts/database/query_builder_interface.dart';
import '../../contracts/database/schema_builder.dart';
import 'database_factory.dart';

/// Manages the active database connection and builder.
class DatabaseManager {
  late final ConfigInterface _config;
  late final ConnectionInterface _connection;
  late final SchemaBuilder _schemaBuilder;

  DatabaseManager(this._config);

  /// Initializes the connection.
  Future<String> init() async {
    final (factory, defaultDriverName) = DatabaseFactory.resolve(_config);
    _schemaBuilder = factory.createSchemaBuilder();

    if (_config.section('database') != null &&
        _config.section('database')!.isNotEmpty) {
      final connection = factory.createConnection(
        _config.section('database') ?? {},
      );
      await connection.connect();
      _connection = connection;
    }

    return defaultDriverName;
  }

  /// Gets a query builder for the given table.
  QueryBuilderInterface<T> table<T>(String tableName,
      {T Function(Map<String, dynamic>)? modelFactory,}) {
    return _connection.queryBuilder<T>(tableName, modelFactory: modelFactory);
  }

  /// Gets the current connection.
  ConnectionInterface get connection => _connection;

  /// Gets the current schema builder.
  SchemaBuilder get schemaBuilder => _schemaBuilder;

  /// Closes the active connection.
  Future<void> close() async => _connection.disconnect();
}
