import 'package:test/test.dart';
import '../../../lib/src/core/database/model_base/khadem_model.dart';
import '../../../lib/src/core/database/orm/relation_definition.dart';
import '../../../lib/src/core/database/orm/relation_type.dart';

// Mock model for testing
class User extends KhademModel<User> {
  String? name;
  String? email;

  User({this.name, this.email});

  @override
  User newFactory(Map<String, dynamic> data) {
    return User(
      name: data['name'],
      email: data['email'],
    );
  }

  @override
  List<String> get fillable => ['name', 'email'];

  @override
  Map<String, RelationDefinition> get relations => {
    'posts': RelationDefinition<Post>(
      type: RelationType.hasMany,
      relatedTable: 'posts',
      localKey: 'id',
      foreignKey: 'user_id',
      factory: () => Post(),
    ),
  };

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
      case 'name':
        name = value;
      case 'email':
        email = value;
    }
  }
}

class Post extends KhademModel<Post> {
  String? title;
  String? content;

  Post({this.title, this.content});

  @override
  Post newFactory(Map<String, dynamic> data) {
    return Post(
      title: data['title'],
      content: data['content'],
    );
  }

  @override
  List<String> get fillable => ['title', 'content'];

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'title':
        return title;
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
      case 'title':
        title = value;
      case 'content':
        content = value;
    }
  }
}

void main() {
  group('KhademModel Laravel-like Features', () {
    late User user;

    setUp(() {
      user = User(name: 'John Doe', email: 'john@example.com');
      user.id = 1; // Set id after creation
    });

    test('should append attributes to model', () {
      user.append(['full_name']);

      expect(user.hasAppended('full_name'), isTrue);
    });

    test('should append single attribute', () {
      user.appendAttribute('display_name');

      expect(user.hasAppended('display_name'), isTrue);
    });

    test('should set and get appended attributes', () {
      user.setAppended('custom_field', 'custom_value');

      expect(user.getAppended('custom_field'), equals('custom_value'));
      expect(user.hasAppended('custom_field'), isTrue);
    });

    test('should check if relation is loaded', () {
      expect(user.isRelationLoaded('posts'), isFalse);

      user.setRelation('posts', []);

      expect(user.isRelationLoaded('posts'), isTrue);
    });

    test('should get and set relations', () {
      final posts = [Post(title: 'Test Post')];

      user.setRelation('posts', posts);

      expect(user.getRelation('posts'), equals(posts));
    });

    test('should return only specified attributes', () {
      final result = user.only(['name']);

      expect(result.containsKey('name'), isTrue);
      expect(result.containsKey('email'), isFalse);
    });

    test('should return all attributes except specified ones', () {
      final result = user.except(['email']);

      expect(result.containsKey('name'), isTrue);
      expect(result.containsKey('email'), isFalse);
    });

    test('should have correct model properties', () {
      expect(user.modelName, equals('User'));
      expect(user.tableName, equals('users'));
      expect(user.fillable, contains('name'));
      expect(user.fillable, contains('email'));
    });

    test('should handle computed properties', () {
      // Test with computed property
      final userWithComputed = User(name: 'John', email: 'john@test.com')
        ..computed['full_name'] = 'John Doe';

      expect(userWithComputed.computed.containsKey('full_name'), isTrue);
    });
  });
}
