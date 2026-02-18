import 'package:khadem/src/contracts/database/database_connection.dart';
import 'package:khadem/src/contracts/database/database_response.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:khadem/src/contracts/database/schema_builder.dart';
import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/relations/belongs_to_many.dart';
import 'package:khadem/src/core/database/orm/relations/has_many_through.dart';
import 'package:khadem/src/core/database/orm/relations/has_one_through.dart';
import 'package:khadem/src/core/database/orm/relations/morph_to.dart';
import 'package:khadem/src/core/database/orm/relations/morph_to_many.dart';
import 'package:khadem/src/core/database/orm/relations/morphed_by_many.dart';
import 'package:khadem/src/core/database/query/grammars/mysql_grammar.dart';
import 'package:khadem/src/core/database/query/query_builder.dart';
import 'package:test/test.dart';

class _MockConnection implements DatabaseConnection {
  @override
  Future<DatabaseResponse> execute(
    String query, [
    List<dynamic> bindings = const [],
  ]) async {
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
  SchemaBuilder getSchemaBuilder() => throw UnimplementedError();

  @override
  Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
    String? isolationLevel,
  }) async {
    return callback();
  }

  @override
  Future<bool> ping() async => true;
}

class Country extends KhademModel<Country> {
  @override
  Country newFactory(Map<String, dynamic> data) => Country()..fromJson(data);
}

class User extends KhademModel<User> {
  @override
  User newFactory(Map<String, dynamic> data) => User()..fromJson(data);
}

class Post extends KhademModel<Post> {
  @override
  Post newFactory(Map<String, dynamic> data) => Post()..fromJson(data);
}

class Tag extends KhademModel<Tag> {
  @override
  Tag newFactory(Map<String, dynamic> data) => Tag()..fromJson(data);
}

class Role extends KhademModel<Role> {
  @override
  Role newFactory(Map<String, dynamic> data) => Role()..fromJson(data);
}

class Comment extends KhademModel<Comment> {
  @override
  Comment newFactory(Map<String, dynamic> data) => Comment()..fromJson(data);
}

void main() {
  late DatabaseConnection mockConnection;

  setUp(() {
    mockConnection = _MockConnection();
  });

  group('HasManyThrough', () {
    test('generates correct SQL for hasManyThrough', () {
      final country = Country()..setAttribute('id', 1);
      final query = QueryBuilder<Post>(mockConnection, MySQLGrammar(), 'posts');

      final relation = HasManyThrough<Post, Country>(
        query,
        country,
        () => Post(),
        'users', // through table
        'country_id', // first key (on users table)
        'user_id', // second key (on posts table)
        'id', // local key (on country table)
        'id', // second local key (on users table)
      );

      relation.addConstraints();

      final sql = relation.getQuery().toSql();
      // select * from `posts` inner join `users` on `users`.`id` = `posts`.`user_id` where `users`.`country_id` = ?
      expect(
        sql,
        contains('INNER JOIN `users` ON `users`.`id` = `posts`.`user_id`'),
      );
      expect(sql, contains('WHERE `users`.`country_id` = ?'));
      expect(relation.getQuery().bindings, equals([1]));
    });

    test('generates correct SQL for eager loading hasManyThrough', () {
      final country = Country()..setAttribute('id', 1);
      final query = QueryBuilder<Post>(mockConnection, MySQLGrammar(), 'posts');

      final relation = HasManyThrough<Post, Country>(
        query,
        country,
        () => Post(),
        'users',
        'country_id',
        'user_id',
        'id',
        'id',
      );

      relation.addEagerConstraints([country]);

      final sql = relation.getQuery().toSql();
      // select `posts`.*, users.country_id as khadem_through_key from `posts` inner join `users` on `users`.`id` = `posts`.`user_id` where `users`.`country_id` in (?)
      expect(
        sql,
        contains('SELECT `posts`.*, users.country_id as khadem_through_key'),
      );
      expect(
        sql,
        contains('INNER JOIN `users` ON `users`.`id` = `posts`.`user_id`'),
      );
      expect(sql, contains('WHERE `users`.`country_id` IN (?)'));
    });
  });

  group('HasOneThrough', () {
    test('generates correct SQL for hasOneThrough', () {
      final mechanic = User()..setAttribute('id', 1); // Mechanic
      final query = QueryBuilder<Post>(
        mockConnection,
        MySQLGrammar(),
        'owners',
      ); // Car Owner

      // Mechanic has one Car Owner through Car
      final relation = HasOneThrough<Post, User>(
        query,
        mechanic,
        () => Post(),
        'cars', // through table
        'mechanic_id', // first key
        'car_id', // second key
        'id', // local key
        'id', // second local key
      );

      relation.addConstraints();

      final sql = relation.getQuery().toSql();
      expect(
        sql,
        contains('INNER JOIN `cars` ON `cars`.`id` = `owners`.`car_id`'),
      );
      expect(sql, contains('WHERE `cars`.`mechanic_id` = ?'));
    });
  });

  group('MorphToMany', () {
    test('generates correct SQL for morphToMany', () {
      final post = Post()..setAttribute('id', 1);
      final query = QueryBuilder<Tag>(mockConnection, MySQLGrammar(), 'tags');

      final relation = MorphToMany<Tag, Post>(
        query,
        post,
        () => Tag(),
        'taggables', // pivot table
        'taggable_id', // foreign pivot key
        'tag_id', // related pivot key
        'id', // parent key
        'id', // related key
        'taggable_type', // morph type
        'posts', // morph class
      );

      relation.addConstraints();

      final sql = relation.getQuery().toSql();
      // select `tags`.*, `taggables`.`taggable_id` as pivot_taggable_id, `taggables`.`tag_id` as pivot_tag_id from `tags` inner join `taggables` on `tags`.`id` = `taggables`.`tag_id` where `taggables`.`taggable_id` = ? and `taggables`.`taggable_type` = ?
      expect(
        sql,
        contains(
          'INNER JOIN `taggables` ON `tags`.`id` = `taggables`.`tag_id`',
        ),
      );
      expect(sql, contains('WHERE `taggables`.`taggable_id` = ?'));
      expect(sql, contains('AND `taggables`.`taggable_type` = ?'));
      expect(relation.getQuery().bindings, equals([1, 'posts']));
    });
  });

  group('MorphedByMany', () {
    test('generates correct SQL for morphedByMany', () {
      final tag = Tag()..setAttribute('id', 1);
      final query = QueryBuilder<Post>(mockConnection, MySQLGrammar(), 'posts');

      final relation = MorphedByMany<Post, Tag>(
        query,
        tag,
        () => Post(),
        'taggables', // pivot table
        'tag_id', // foreign pivot key
        'taggable_id', // related pivot key
        'id', // parent key
        'id', // related key
        'taggable_type', // morph type
        'posts', // morph class
      );

      relation.addConstraints();

      final sql = relation.getQuery().toSql();
      expect(
        sql,
        contains(
          'INNER JOIN `taggables` ON `posts`.`id` = `taggables`.`taggable_id`',
        ),
      );
      expect(sql, contains('WHERE `taggables`.`tag_id` = ?'));
      expect(sql, contains('AND `taggables`.`taggable_type` = ?'));
      expect(relation.getQuery().bindings, equals([1, 'posts']));
    });
  });

  group('BelongsToMany', () {
    test('selects pivot keys and matches results back to parents', () {
      final user = User()..setAttribute('id', 1);
      final query = QueryBuilder<Role>(mockConnection, MySQLGrammar(), 'roles');

      final relation = BelongsToMany<Role, User>(
        query,
        user,
        () => Role(),
        'user_roles',
        'user_id',
        'role_id',
        'id',
        'id',
      );

      relation.addEagerConstraints([user]);

      final sql = relation.getQuery().toSql();
      expect(sql, contains('user_roles.user_id as khadem_pivot_foreign_key'));
      expect(sql, contains('user_roles.role_id as khadem_pivot_related_key'));

      final role = Role()
        ..setAttribute('id', 10)
        ..setAttribute('khadem_pivot_foreign_key', 1);

      relation.initRelation([user], 'roles');
      relation.match([user], [role], 'roles');

      final loaded = user.getRelation('roles') as List<Role>;
      expect(loaded.length, 1);
      expect(loaded.first.getAttribute('id'), 10);
    });
  });

  group('MorphTo', () {
    test('adds constraints when morph type matches', () {
      final comment = Comment()
        ..setAttribute('commentable_id', 5)
        ..setAttribute('commentable_type', 'Post');

      final query = QueryBuilder<Post>(mockConnection, MySQLGrammar(), 'posts');

      final relation = MorphTo<Post, Comment>(
        query,
        comment,
        () => Post(),
        'commentable_type',
        'commentable_id',
        'Post',
        'id',
        'commentable',
      );

      relation.addConstraints();

      final sql = relation.getQuery().toSql();
      expect(sql, contains('WHERE `id` = ?'));
      expect(relation.getQuery().bindings, equals([5]));
    });

    test('adds no-match constraint when morph type mismatches', () {
      final comment = Comment()
        ..setAttribute('commentable_id', 5)
        ..setAttribute('commentable_type', 'User');

      final query = QueryBuilder<Post>(mockConnection, MySQLGrammar(), 'posts');

      final relation = MorphTo<Post, Comment>(
        query,
        comment,
        () => Post(),
        'commentable_type',
        'commentable_id',
        'Post',
        'id',
        'commentable',
      );

      relation.addConstraints();

      final sql = relation.getQuery().toSql();
      expect(sql, contains('WHERE 1 = 0'));
    });
  });
}
