import 'package:khadem/src/contracts/database/database_connection.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:khadem/src/contracts/database/schema_builder.dart';
import 'package:khadem/src/core/database/database.dart';

class FakeDatabaseManager implements DatabaseManager {
  late final DatabaseConnection _connection;

  @override
  Future<String> init() async => 'fake';

  @override
  QueryBuilderInterface<T> table<T>(
    String tableName, {
    T Function(Map<String, dynamic>)? modelFactory,
    String? connectionName,
  }) {
    return FakeQueryBuilder<T>();
  }

  @override
  DatabaseConnection connection([String? name]) {
    return _connection;
  }

  @override
  SchemaBuilder get schemaBuilder => throw UnimplementedError();

  @override
  Future<void> close() async {}
}

class FakeQueryBuilder<T> implements QueryBuilderInterface<T> {
  @override
  QueryBuilderInterface<T> where(
    String column,
    String operator, [
    dynamic value,
  ]) =>
      this;

  @override
  QueryBuilderInterface<T> whereNotNull(String column) => this;

  @override
  QueryBuilderInterface<T> whereNull(String column) => this;

  @override
  QueryBuilderInterface<T> whereLike(String column, dynamic value) => this;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return self for chaining methods that return QueryBuilderInterface
    if (invocation.memberName == #orderBy ||
        invocation.memberName == #limit ||
        invocation.memberName == #offset ||
        invocation.memberName == #select) {
      return this;
    }
    return null;
  }
}
