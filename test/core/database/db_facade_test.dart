import 'package:khadem/khadem.dart';
import 'package:test/test.dart';

import '../../mocks/db_facade_test.mocks.dart';

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
