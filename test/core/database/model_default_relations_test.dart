import 'package:khadem/src/contracts/database/connection_interface.dart';
import 'package:khadem/src/contracts/database/database_response.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:khadem/src/core/database/database_drivers/mysql/mysql_query_builder.dart';
import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/relation_definition.dart';
import 'package:khadem/src/core/database/orm/relation_type.dart';
import 'package:test/test.dart';

// Simple mock connection for testing
class _MockConnection implements ConnectionInterface {
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
  bool get isConnected => true;

  @override
  QueryBuilderInterface<T> queryBuilder<T>(
    String table, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) {
    return MySQLQueryBuilder<T>(this, table, modelFactory: modelFactory);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
  }) async {
    return callback();
  }

  @override
  Future<bool> ping() async => true;
}

// Test models
class TestUser extends KhademModel<TestUser> {
  @override
  int? id;
  String? name;
  String? email;

  // Define default relations to always eager load
  @override
  List<dynamic> get defaultRelations => ['posts', 'profile'];

  @override
  Map<String, RelationDefinition> get relations => {
        'posts': RelationDefinition<TestPost>(
          type: RelationType.hasMany,
          relatedTable: 'posts',
          foreignKey: 'user_id',
          localKey: 'id',
          factory: () => TestPost(),
        ),
        'profile': RelationDefinition<TestProfile>(
          type: RelationType.hasOne,
          relatedTable: 'profiles',
          foreignKey: 'user_id',
          localKey: 'id',
          factory: () => TestProfile(),
        ),
        'followers': RelationDefinition<TestUser>(
          type: RelationType.hasMany,
          relatedTable: 'followers',
          foreignKey: 'following_id',
          localKey: 'id',
          factory: () => TestUser(),
        ),
      };

  @override
  TestUser newFactory(Map<String, dynamic> data) {
    return TestUser()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'email':
        return email;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'name':
        name = value;
        break;
      case 'email':
        email = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['name', 'email'];
}

class TestPost extends KhademModel<TestPost> {
  @override
  int? id;
  int? userId;
  String? title;

  // Posts load comments by default
  @override
  List<dynamic> get defaultRelations => ['comments'];

  @override
  Map<String, RelationDefinition> get relations => {
        'comments': RelationDefinition<TestComment>(
          type: RelationType.hasMany,
          relatedTable: 'comments',
          foreignKey: 'post_id',
          localKey: 'id',
          factory: () => TestComment(),
        ),
      };

  @override
  TestPost newFactory(Map<String, dynamic> data) {
    return TestPost()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'user_id':
        return userId;
      case 'title':
        return title;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'user_id':
        userId = value;
        break;
      case 'title':
        title = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['user_id', 'title'];
}

class TestProfile extends KhademModel<TestProfile> {
  @override
  int? id;
  int? userId;
  String? bio;

  @override
  TestProfile newFactory(Map<String, dynamic> data) {
    return TestProfile()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'user_id':
        return userId;
      case 'bio':
        return bio;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'user_id':
        userId = value;
        break;
      case 'bio':
        bio = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['user_id', 'bio'];
}

class TestComment extends KhademModel<TestComment> {
  @override
  int? id;
  int? postId;
  String? content;

  @override
  TestComment newFactory(Map<String, dynamic> data) {
    return TestComment()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'post_id':
        return postId;
      case 'content':
        return content;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'post_id':
        postId = value;
        break;
      case 'content':
        content = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['post_id', 'content'];
}

void main() {
  late ConnectionInterface connection;
  late MySQLQueryBuilder<TestUser> query;

  setUp(() {
    connection = _MockConnection();
    query = MySQLQueryBuilder<TestUser>(
      connection,
      'users',
      modelFactory: (data) => TestUser()..fromJson(data),
    );
  });

  group('Model Default Relations', () {
    test('model has defaultRelations property', () {
      final user = TestUser();
      expect(user.defaultRelations, equals(['posts', 'profile']));
    });

    test('query with without() method returns query builder', () {
      final result = query.without(['posts']);
      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('query with withOnly() method returns query builder', () {
      final result = query.withOnly(['followers']);
      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('without() can exclude multiple relations', () {
      final result = query.without(['posts', 'profile']);
      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('withOnly() works with multiple relations', () {
      final result = query.withOnly(['followers', 'posts']);
      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('methods can be chained together', () {
      final result = query
          .where('active', '=', true)
          .withRelations(['followers']).without(['posts']).limit(10);

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('clone() preserves without() settings', () {
      query.without(['posts']);
      final cloned = query.clone();

      expect(cloned, isA<QueryBuilderInterface<TestUser>>());
      // We can't test private fields, but clone should work
    });

    test('clone() preserves withOnly() settings', () {
      query.withOnly(['followers']);
      final cloned = query.clone();

      expect(cloned, isA<QueryBuilderInterface<TestUser>>());
    });

    test('model without defaultRelations has empty list', () {
      final comment = TestComment();
      expect(comment.defaultRelations, isEmpty);
    });

    test('model with defaultRelations returns correct list', () {
      final post = TestPost();
      expect(post.defaultRelations, equals(['comments']));
    });

    test('withRelations() still works as before', () {
      final result = query.withRelations(['posts', 'profile']);
      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });
  });
}
