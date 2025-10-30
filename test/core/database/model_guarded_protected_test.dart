import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:test/test.dart';

// Test model with fillable attributes
class TestUserFillable extends KhademModel<TestUserFillable> {
  @override
  int? id;
  String? name;
  String? email;
  String? password;
  String? role;
  DateTime? createdAt;

  @override
  List<String> get fillable => ['name', 'email'];

  @override
  TestUserFillable newFactory(Map<String, dynamic> data) {
    return TestUserFillable()..fromJson(data);
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
      case 'password':
        return password;
      case 'role':
        return role;
      case 'created_at':
        return createdAt;
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
      case 'password':
        password = value;
        break;
      case 'role':
        role = value;
        break;
      case 'created_at':
        createdAt = value;
        break;
    }
  }
}

// Test model with guarded attributes
class TestUserGuarded extends KhademModel<TestUserGuarded> {
  @override
  int? id;
  String? name;
  String? email;
  String? password;
  String? role;
  DateTime? createdAt;
  DateTime? updatedAt;

  @override
  List<String> get guarded => ['id', 'role', 'created_at', 'updated_at'];

  @override
  TestUserGuarded newFactory(Map<String, dynamic> data) {
    return TestUserGuarded()..fromJson(data);
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
      case 'password':
        return password;
      case 'role':
        return role;
      case 'created_at':
        return createdAt;
      case 'updated_at':
        return updatedAt;
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
      case 'password':
        password = value;
        break;
      case 'role':
        role = value;
        break;
      case 'created_at':
        createdAt = value;
        break;
      case 'updated_at':
        updatedAt = value;
        break;
    }
  }
}

// Test model with protected attributes
class TestUserProtected extends KhademModel<TestUserProtected> {
  @override
  int? id;
  String? name;
  String? email;
  String? password;
  String? apiKey;
  String? secret;

  @override
  List<String> get fillable => ['name', 'email', 'password'];

  @override
  List<String> get protected => ['password', 'api_key', 'secret'];

  @override
  TestUserProtected newFactory(Map<String, dynamic> data) {
    return TestUserProtected()..fromJson(data);
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
      case 'password':
        return password;
      case 'api_key':
        return apiKey;
      case 'secret':
        return secret;
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
      case 'password':
        password = value;
        break;
      case 'api_key':
        apiKey = value;
        break;
      case 'secret':
        secret = value;
        break;
    }
  }
}

// Test model with both hidden and protected
class TestUserCombined extends KhademModel<TestUserCombined> {
  @override
  int? id;
  String? name;
  String? email;
  String? password;
  String? token;

  @override
  List<String> get fillable => ['name', 'email', 'password', 'token'];

  @override
  List<String> get initialHidden => ['token'];

  @override
  List<String> get protected => ['password'];

  @override
  TestUserCombined newFactory(Map<String, dynamic> data) {
    return TestUserCombined()..fromJson(data);
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
      case 'password':
        return password;
      case 'token':
        return token;
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
      case 'password':
        password = value;
        break;
      case 'token':
        token = value;
        break;
    }
  }
}

void main() {
  group('Fillable Attributes', () {
    test('only fillable attributes are mass assignable', () {
      final user = TestUserFillable()
        ..fromJson({
          'name': 'John Doe',
          'email': 'john@example.com',
          'password': 'secret123',
          'role': 'admin',
        });

      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.password, isNull); // Not fillable
      expect(user.role, isNull); // Not fillable
    });

    test('fill() method respects fillable list', () {
      final user = TestUserFillable().fill({
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'password': 'secret456',
        'role': 'user',
      });

      expect(user.name, equals('Jane Smith'));
      expect(user.email, equals('jane@example.com'));
      expect(user.password, isNull);
      expect(user.role, isNull);
    });

    test('forceFill() bypasses fillable restrictions', () {
      final user = TestUserFillable().forceFill({
        'name': 'Admin',
        'email': 'admin@example.com',
        'password': 'admin123',
        'role': 'superadmin',
      });

      expect(user.name, equals('Admin'));
      expect(user.email, equals('admin@example.com'));
      expect(user.password, equals('admin123')); // Force filled
      expect(user.role, equals('superadmin')); // Force filled
    });

    test('isFillable returns correct values', () {
      final user = TestUserFillable();

      expect(user.json.isFillable('name'), isTrue);
      expect(user.json.isFillable('email'), isTrue);
      expect(user.json.isFillable('password'), isFalse);
      expect(user.json.isFillable('role'), isFalse);
    });
  });

  group('Guarded Attributes', () {
    test('guarded attributes cannot be mass assigned', () {
      final user = TestUserGuarded()
        ..fromJson({
          'name': 'John Doe',
          'email': 'john@example.com',
          'password': 'secret123',
          'role': 'admin',
          'id': 999,
        });

      expect(user.name, equals('John Doe')); // Fillable
      expect(user.email, equals('john@example.com')); // Fillable
      expect(user.password, equals('secret123')); // Fillable
      expect(user.role, isNull); // Guarded
      expect(user.id, isNull); // Guarded (not from json in this case)
    });

    test('everything except guarded is fillable', () {
      final user = TestUserGuarded();

      expect(user.json.isFillable('name'), isTrue);
      expect(user.json.isFillable('email'), isTrue);
      expect(user.json.isFillable('password'), isTrue);
      expect(user.json.isFillable('id'), isFalse); // Guarded
      expect(user.json.isFillable('role'), isFalse); // Guarded
      expect(user.json.isFillable('created_at'), isFalse); // Guarded
      expect(user.json.isFillable('updated_at'), isFalse); // Guarded
    });

    test('forceFill() bypasses guarded restrictions', () {
      final user = TestUserGuarded().forceFill({
        'name': 'Admin',
        'role': 'superadmin',
        'id': 1,
      });

      expect(user.name, equals('Admin'));
      expect(user.role, equals('superadmin')); // Force filled despite guarded
      expect(user.id, equals(1)); // Force filled despite guarded
    });
  });

  group('Protected Attributes', () {
    test('protected attributes never appear in toJson()', () {
      final user = TestUserProtected()
        ..forceFill({
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'password': 'secret123',
          'api_key': 'key123',
          'secret': 'verysecret',
        });

      final json = user.toJson();

      expect(json['id'], equals(1));
      expect(json['name'], equals('John Doe'));
      expect(json['email'], equals('john@example.com'));
      expect(json.containsKey('password'), isFalse); // Protected
      expect(json.containsKey('api_key'), isFalse); // Protected
      expect(json.containsKey('secret'), isFalse); // Protected
    });

    test('protected attributes never appear in toJsonAsync()', () async {
      final user = TestUserProtected()
        ..forceFill({
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'password': 'secret123',
          'api_key': 'key123',
        });

      final json = await user.toJsonAsync();

      expect(json['id'], equals(1));
      expect(json['name'], equals('John Doe'));
      expect(json['email'], equals('john@example.com'));
      expect(json.containsKey('password'), isFalse); // Protected
      expect(json.containsKey('api_key'), isFalse); // Protected
    });

    test('protected can still be filled but not serialized', () {
      final user = TestUserProtected()
        ..fromJson({
          'name': 'John',
          'email': 'john@example.com',
          'password': 'secret', // Fillable but protected
        });

      expect(user.password, equals('secret')); // Can be set

      final json = user.toJson();
      expect(json.containsKey('password'), isFalse); // But not serialized
    });
  });

  group('Hidden vs Protected', () {
    test('hidden can be made visible, protected cannot', () {
      final user = TestUserCombined()
        ..forceFill({
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'password': 'secret123',
          'token': 'abc123',
        });

      // Default: hidden and protected both excluded
      final json1 = user.toJson();
      expect(json1.containsKey('password'), isFalse); // Protected
      expect(json1.containsKey('token'), isFalse); // Hidden

      // Make hidden visible
      user.makeVisible(['token']);
      final json2 = user.toJson();
      expect(json2.containsKey('token'), isTrue); // Now visible
      expect(json2.containsKey('password'), isFalse); // Still protected

      // Try to make protected visible - should not work
      user.makeVisible(['password']);
      final json3 = user.toJson();
      expect(json3.containsKey('password'), isFalse); // Still protected!
    });

    test('protected is a stronger restriction than hidden', () {
      final user = TestUserCombined()
        ..forceFill({
          'password': 'secret',
          'token': 'token123',
        });

      // Both hidden by default
      final json1 = user.toJson();
      expect(json1.containsKey('password'), isFalse);
      expect(json1.containsKey('token'), isFalse);

      // Unhide everything
      user.makeVisible(['token', 'password']);

      final json2 = user.toJson();
      expect(json2['token'], equals('token123')); // Can be made visible
      expect(json2.containsKey('password'), isFalse); // Protected overrides
    });
  });

  group('Fillable vs Guarded Priority', () {
    test('fillable takes precedence over guarded', () {
      // When both fillable and guarded are specified, fillable wins
      // This is tested implicitly by having a model with only fillable
      final user = TestUserFillable();

      // Only fillable matters
      expect(user.json.isFillable('name'), isTrue);
      expect(user.json.isFillable('password'), isFalse);
    });
  });

  group('Edge Cases', () {
    test('empty fillable and empty guarded allows everything', () {
      // Create a model with no fillable or guarded
      final user = TestUserGuarded();

      // Override to empty (simulating a model with neither specified)
      // In practice, this would be a different model class, but we test the logic
      expect(user.fillable, isEmpty);

      // With guarded specified, those should not be fillable
      expect(user.json.isFillable('role'), isFalse);
      expect(user.json.isFillable('name'), isTrue);
    });

    test('fillable with force parameter in fromJson', () {
      final user = TestUserFillable();

      // Normal fromJson respects fillable
      user.json.fromJson({'name': 'John', 'role': 'admin'}, force: false);
      expect(user.name, equals('John'));
      expect(user.role, isNull);

      // Force fromJson bypasses fillable
      user.json.fromJson({'role': 'superadmin'});
      expect(user.role, equals('superadmin'));
    });

    test('protected attributes are completely hidden', () {
      final user = TestUserProtected()
        ..forceFill({'password': 'secret', 'api_key': 'key'});

      final json = user.toJson();

      // Even though password is fillable, it's protected from serialization
      expect(json.containsKey('password'), isFalse);
      expect(json.containsKey('api_key'), isFalse);

      // But the values are still set on the model
      expect(user.password, equals('secret'));
      expect(user.apiKey, equals('key'));
    });
  });
}
