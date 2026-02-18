import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/relation_definition.dart';
import 'package:khadem/src/core/database/orm/relation_type.dart';
import 'package:test/test.dart';

// Test models for async computed properties
class TestUser extends KhademModel<TestUser> {
  @override
  int? id;
  String? firstName;
  String? lastName;
  int? postCount;

  @override
  List<String> get fillable => ['first_name', 'last_name', 'post_count'];

  @override
  Map<String, dynamic> get appends => {
        // Synchronous computed property
        'full_name': () =>
            '${getAttribute('first_name')} ${getAttribute('last_name')}',

        // Async computed property with Future
        'greeting': () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'Hello, ${getAttribute('first_name')}!';
        },

        // Async computed property using relations
        'post_summary': () async {
          // Only try to load if not already loaded
          if (!relationLoaded('posts')) {
            return 'No posts loaded';
          }
          final posts = getRelation('posts') as List<TestPost>? ?? [];
          return '${posts.length} posts';
        },

        // Mixed - can return sync or async based on condition
        'dynamic_value': () {
          final count = getAttribute('post_count');
          if (count != null && count > 0) {
            return count; // Sync
          }
          // Async
          return Future.delayed(
            const Duration(milliseconds: 5),
            () => 0,
          );
        },
      };

  @override
  Map<String, RelationDefinition> get relations => {
        'posts': RelationDefinition<TestPost>(
          type: RelationType.hasMany,
          relatedTable: 'posts',
          foreignKey: 'user_id',
          localKey: 'id',
          factory: () => TestPost(),
        ),
      };

  @override
  TestUser newFactory(Map<String, dynamic> data) {
    return TestUser()..fromJson(data);
  }

  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'first_name':
        return firstName;
      case 'last_name':
        return lastName;
      case 'post_count':
        return postCount;
      default:
        return null;
    }
  }

  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'first_name':
        firstName = value;
        break;
      case 'last_name':
        lastName = value;
        break;
      case 'post_count':
        postCount = value;
        break;
    }
  }
}

class TestPost extends KhademModel<TestPost> {
  @override
  int? id;
  int? userId;
  String? title;

  @override
  TestPost newFactory(Map<String, dynamic> data) {
    return TestPost()..fromJson(data);
  }

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

void main() {
  group('Async Computed Properties', () {
    test('synchronous computed property works with getAttribute', () {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      final fullName = user.getAttribute('full_name');

      expect(fullName, equals('John Doe'));
    });

    test('async computed property returns Future with getAttribute', () {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // Sync getter returns Future for async properties
      final greeting = user.getAttribute('greeting');

      expect(greeting, isA<Future>());
    });

    test('async computed property resolves with await getAttribute', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      final greeting = await user.getAttribute('greeting');

      expect(greeting, equals('Hello, John!'));
    });

    test('await getAttribute works with sync properties too', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      final fullName = await user.getAttribute('full_name');

      expect(fullName, equals('John Doe'));
    });

    test('async computed property can use relations', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // Manually set relation to simulate eager loading
      final posts = [
        TestPost()..fromJson({'id': 1, 'user_id': 1, 'title': 'Post 1'}),
        TestPost()..fromJson({'id': 2, 'user_id': 1, 'title': 'Post 2'}),
      ];
      user.setRelation('posts', posts);

      final summary = await user.getAttribute('post_summary');

      expect(summary, equals('2 posts'));
    });

    test('toMap uses sync version and returns Future for async properties',
        () {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // Set empty relation to avoid database call
      user.setRelation('posts', <TestPost>[]);

      final map = user.toMap();

      expect(map['full_name'], equals('John Doe')); // Sync works
      expect(map['greeting'], isA<Future>()); // Async returns Future
      expect(map['post_summary'], isA<Future>()); // Async returns Future
    });

    test('toJsonAsync properly resolves all async computed properties',
        () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // Manually set relation
      user.setRelation('posts', <TestPost>[]);

      final json = await user.toJsonAsync();

      expect(json['full_name'], equals('John Doe'));
      expect(json['greeting'], equals('Hello, John!'));
      expect(json['post_summary'], equals('0 posts'));
    });

    test('toJsonAsync handles relations correctly', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'Jane', 'last_name': 'Smith'});

      final posts = [
        TestPost()..fromJson({'id': 1, 'user_id': 1, 'title': 'Post 1'}),
        TestPost()..fromJson({'id': 2, 'user_id': 1, 'title': 'Post 2'}),
        TestPost()..fromJson({'id': 3, 'user_id': 1, 'title': 'Post 3'}),
      ];
      user.setRelation('posts', posts);

      final json = await user.toJsonAsync();

      expect(json['first_name'], equals('Jane'));
      expect(json['last_name'], equals('Smith'));
      expect(json['full_name'], equals('Jane Smith'));
      expect(json['greeting'], equals('Hello, Jane!'));
      expect(json['post_summary'], equals('3 posts'));
    });

    test('async computed property handles errors gracefully', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // Non-existent computed property
      final result = await user.getAttribute('non_existent');

      expect(result, isNull);
    });

    test('mixed sync/async computed property works', () async {
      final user1 = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'post_count': 5});

      final user2 = TestUser()
        ..fromJson({'id': 2, 'first_name': 'Jane', 'post_count': null});

      // User1 has post_count, should return sync
      final value1 = await user1.getAttribute('dynamic_value');
      expect(value1, equals(5));

      // User2 has no post_count, should return async (0 after delay)
      final value2 = await user2.getAttribute('dynamic_value');
      expect(value2, equals(0));
    });

    test('toMap with async properties requires toJsonAsync', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      user.setRelation('posts', <TestPost>[]);

      // Regular toMap() returns Futures for async
      final syncMap = user.toMap();
      expect(syncMap['greeting'], isA<Future>());
      expect(syncMap['post_summary'], isA<Future>());

      // toJsonAsync() resolves them
      final asyncJson = await user.toJsonAsync();
      expect(asyncJson['greeting'], equals('Hello, John!'));
      expect(asyncJson['post_summary'], equals('0 posts'));
    });

    test('computed properties without Function type work', () async {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // This should work even with non-function values
      final result = await user.getAttribute('full_name');
      expect(result, equals('John Doe'));
    });
  });

  group('Backward Compatibility', () {
    test('models without async computed properties work normally', () {
      final post = TestPost()
        ..fromJson({'id': 1, 'user_id': 1, 'title': 'Test'});

      final json = post.toJson();

      expect(json['id'], equals(1));
      expect(json['title'], equals('Test'));
    });

    test('toJsonAsync works for models without async properties', () async {
      final post = TestPost()
        ..fromJson({'id': 1, 'user_id': 1, 'title': 'Test'});

      final json = await post.toJsonAsync();

      expect(json['id'], equals(1));
      expect(json['title'], equals('Test'));
    });

    test('existing synchronous computed properties unchanged', () {
      final user = TestUser()
        ..fromJson({'id': 1, 'first_name': 'John', 'last_name': 'Doe'});

      // Set empty relation to avoid database call
      user.setRelation('posts', <TestPost>[]);

      // Old way still works
      final fullName = user.getAttribute('full_name');
      expect(fullName, equals('John Doe'));

      // JSON serialization still works
      final json = user.toJson();
      expect(json['full_name'], equals('John Doe'));
    });
  });
}
