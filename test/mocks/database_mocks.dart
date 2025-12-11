import 'package:khadem/src/core/database/database.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:khadem/src/contracts/database/connection_interface.dart';
import 'package:khadem/src/contracts/database/schema_builder.dart';
import 'package:khadem/src/contracts/config/config_contract.dart';

class FakeDatabaseManager implements DatabaseManager {
  @override
  late final ConfigInterface _config;
  @override
  late final ConnectionInterface _connection;
  @override
  late final SchemaBuilder _schemaBuilder;

  @override
  Future<String> init() async => 'fake';

  @override
  QueryBuilderInterface<T> table<T>(
    String tableName, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) {
    return FakeQueryBuilder<T>();
  }

  @override
  ConnectionInterface get connection => throw UnimplementedError();

  @override
  SchemaBuilder get schemaBuilder => throw UnimplementedError();

  @override
  Future<void> close() async {}
}

class FakeQueryBuilder<T> implements QueryBuilderInterface<T> {
  @override
  QueryBuilderInterface<T> where(String column, String operator, [dynamic value]) => this;
  
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
