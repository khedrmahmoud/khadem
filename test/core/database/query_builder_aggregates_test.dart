import 'package:khadem/khadem.dart';
import 'package:test/test.dart';

class TestDatabaseManager implements DatabaseManager {
  final DatabaseConnection _connection;

  TestDatabaseManager(this._connection);

  @override
  QueryBuilderInterface<T> table<T>(String tableName,
      {T Function(Map<String, dynamic>)? modelFactory,
      String? connectionName,}) {
    return QueryBuilder<T>(_connection, MySQLGrammar(), tableName,
        modelFactory: modelFactory,);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockConnection implements DatabaseConnection {
  @override
  Future<DatabaseResponse> execute(String query,
      [List<dynamic> bindings = const [],]) async {
    return DatabaseResponse(data: [], affectedRows: 0);
  }

  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> beginTransaction() async {}
  @override
  Future<void> commit() async {}
  @override
  Future<void> rollBack() async {}
  @override
  Future<void> unprepared(String sql) async {}
  @override
  bool get isConnected => true;

  @override
  QueryBuilderInterface<T> queryBuilder<T>(String table,
      {T Function(Map<String, dynamic>)? modelFactory,}) {
    return QueryBuilder<T>(this, MySQLGrammar(), table,
        modelFactory: modelFactory,);
  }

  @override
  SchemaBuilder getSchemaBuilder() => throw UnimplementedError();

  @override
  Future<T> transaction<T>(Future<T> Function() callback,
      {int maxRetries = 3,
      Duration retryDelay = const Duration(milliseconds: 100),
      Future<void> Function(T result)? onSuccess,
      Future<void> Function(dynamic error)? onFailure,
      Future<void> Function()? onFinally,
      String? isolationLevel,}) async {
    return callback();
  }

  @override
  Future<bool> ping() async => true;
}

class Post extends KhademModel<Post> {
  @override
  Post newFactory(Map<String, dynamic> data) => Post()..fromJson(data);
}

class User extends KhademModel<User> {
  @override
  User newFactory(Map<String, dynamic> data) => User()..fromJson(data);

  @override
  Map<String, RelationDefinition> get definedRelations => {
        'posts': hasMany<Post>(
          foreignKey: 'user_id',
          relatedTable: 'posts',
          factory: () => Post(),
        ),
      };
}

void main() {
  late DatabaseConnection mockConnection;
  late DatabaseManager mockDatabaseManager;

  setUp(() {
    mockConnection = _MockConnection();
    mockDatabaseManager = TestDatabaseManager(mockConnection);
    ContainerProvider.instance
        .singleton<DatabaseManager>((_) => mockDatabaseManager);
  });

  tearDown(() {
    ContainerProvider.instance.flush();
  });

  group('QueryBuilder Aggregates', () {
    test('withCount generates correct subquery', () {
      final query = QueryBuilder<User>(
        mockConnection,
        MySQLGrammar(),
        'users',
        modelFactory: (data) => User()..fromJson(data),
      );

      query.withCount('posts');

      final sql = query.toSql();
      // SELECT *, (SELECT COUNT(*) FROM `posts` WHERE `users`.`id` = `posts`.`user_id`) as posts_count FROM `users`
      expect(sql, contains('SELECT *'));
      expect(
          sql,
          contains(
              '(SELECT COUNT(*) FROM `posts` WHERE `posts`.`user_id` = `users`.`id`) as posts_count',),);
    });

    test('withCount supports array of relations', () {
      final query = QueryBuilder<User>(
        mockConnection,
        MySQLGrammar(),
        'users',
        modelFactory: (data) => User()..fromJson(data),
      );

      query.withCount(['posts']);

      final sql = query.toSql();
      expect(sql, contains('posts_count'));
    });

    test('withAvg generates correct subquery', () {
      final query = QueryBuilder<User>(
        mockConnection,
        MySQLGrammar(),
        'users',
        modelFactory: (data) => User()..fromJson(data),
      );

      query.withAvg('posts', 'rating');

      final sql = query.toSql();
      // SELECT *, (SELECT AVG(`rating`) FROM `posts` WHERE `users`.`id` = `posts`.`user_id`) as posts_avg_rating FROM `users`
      expect(
          sql,
          contains(
              '(SELECT AVG(`rating`) FROM `posts` WHERE `posts`.`user_id` = `users`.`id`) as posts_avg_rating',),);
    });

    test('withSum generates correct subquery', () {
      final query = QueryBuilder<User>(
        mockConnection,
        MySQLGrammar(),
        'users',
        modelFactory: (data) => User()..fromJson(data),
      );

      query.withSum('posts', 'views');

      final sql = query.toSql();
      expect(
          sql,
          contains(
              '(SELECT SUM(`views`) FROM `posts` WHERE `posts`.`user_id` = `users`.`id`) as posts_sum_views',),);
    });
  });
}
