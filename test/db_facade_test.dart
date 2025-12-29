import 'package:khadem/khadem.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

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
  QueryBuilderInterface<T> queryBuilder<T>(String table,
      {T Function(Map<String, dynamic>)? modelFactory,}) {
    return QueryBuilder<T>(this, MySQLGrammar(), table,
        modelFactory: modelFactory,);
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
  QueryBuilderInterface<T> table<T>(String tableName,
      {T Function(Map<String, dynamic>)? modelFactory,
      String? connectionName,}) {
    return _connection.queryBuilder(tableName, modelFactory: modelFactory);
  }
}

void main() {
  group('DB Facade', () {
    late ContainerInterface container;
    late MockDatabaseManager manager;

    setUp(() {
      container = ContainerProvider.instance;
      manager = MockDatabaseManager();

      container.singleton<DatabaseManager>((_) => manager);
    });

    test('DB.table returns QueryBuilder', () {
      final query = DB.table('users');
      expect(query, isA<QueryBuilder>());
      expect((query as QueryBuilder).table, equals('users'));
    });

    test('DB.connection returns connection', () {
      final conn = DB.connection();
      expect(conn.isConnected, isTrue);
    });
  });
}
