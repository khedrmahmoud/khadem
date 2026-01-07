import 'package:khadem/src/contracts/database/database_connection.dart';
import 'package:khadem/src/contracts/database/database_response.dart';
import 'package:khadem/src/core/database/query/grammar.dart';
import 'package:khadem/src/core/database/query/grammars/mysql_grammar.dart';
import 'package:khadem/src/core/database/query/query_builder.dart';
import 'package:test/test.dart';

class FakeConnection implements DatabaseConnection {
  List<String> executedSql = [];
  List<List<dynamic>> executedBindings = [];

  @override
  Future<DatabaseResponse> execute(String sql,
      [List<dynamic>? bindings = const [],]) async {
    executedSql.add(sql);
    executedBindings.add(bindings ?? []);
    return DatabaseResponse(affectedRows: 1, insertId: 1, data: []);
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeConnection connection;
  late Grammar grammar;
  late QueryBuilder queryBuilder;

  setUp(() {
    connection = FakeConnection();
    grammar = MySQLGrammar();
    queryBuilder = QueryBuilder(connection, grammar, 'users');
  });

  test('update bindings order with fromRaw and where', () async {
    await queryBuilder
        .fromRaw('users JOIN roles ON users.role_id = ?', [1])
        .where('active', '=', true)
        .update({'name': 'Updated'});

    expect(connection.executedSql.last, contains('UPDATE'));
    // Bindings order: [1 (from), 'Updated' (value), true (where)]
    expect(connection.executedBindings.last, equals([1, 'Updated', true]));
  });

  test('increment bindings order with fromRaw and where', () async {
    await queryBuilder
        .fromRaw('users JOIN roles ON users.role_id = ?', [1])
        .where('active', '=', true)
        .increment('score', 10);

    expect(connection.executedSql.last, contains('UPDATE'));
    // Bindings order: [1 (from), true (where)]
    expect(connection.executedBindings.last, equals([1, true]));
  });

  test('incrementEach bindings order with fromRaw and where', () async {
    await queryBuilder
        .fromRaw('users JOIN roles ON users.role_id = ?', [1])
        .where('active', '=', true)
        .incrementEach({'score': 1}, {'updated_at': '2023-01-01'});

    expect(connection.executedSql.last, contains('UPDATE'));
    // Bindings order: [1 (from), '2023-01-01' (extra), true (where)]
    expect(connection.executedBindings.last, equals([1, '2023-01-01', true]));
  });

  test('delete bindings order with fromRaw and where', () async {
    await queryBuilder
        .fromRaw('users JOIN roles ON users.role_id = ?', [1])
        .where('active', '=', true)
        .delete();

    expect(connection.executedSql.last, contains('DELETE'));
    // Bindings order: [1 (from), true (where)]
    expect(connection.executedBindings.last, equals([1, true]));
  });
}
