import 'package:khadem/contracts.dart'
    show
        ConfigInterface,
        DatabaseConnection,
        QueryBuilderInterface,
        SchemaBuilder;
import 'package:khadem/database/drivers.dart';
import 'package:khadem/database/query.dart';

import 'package:mockito/mockito.dart';

// Mocks
class MockConfig extends Mock implements ConfigInterface {}

class MockConnection extends Mock implements DatabaseConnection {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  bool get isConnected => true;

  @override
  QueryBuilderInterface<T> queryBuilder<T>(
    String table, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) {
    return QueryBuilder<T>(
      this,
      MySQLGrammar(),
      table,
      modelFactory: modelFactory,
    );
  }

  @override
  SchemaBuilder getSchemaBuilder() {
    throw UnimplementedError();
  }
}

class MockDatabaseManager extends Mock implements DatabaseManager {
  final _connection = MockConnection();

  @override
  DatabaseConnection connection([String? name]) {
    return _connection;
  }

  @override
  QueryBuilderInterface<T> table<T>(
    String tableName, {
    T Function(Map<String, dynamic>)? modelFactory,
    String? connectionName,
  }) {
    return _connection.queryBuilder(tableName, modelFactory: modelFactory);
  }
}
