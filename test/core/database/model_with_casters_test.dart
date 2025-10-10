import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/casting/built_in_casters.dart';
import 'package:test/test.dart';

/// Test model using advanced casters
class TestUser extends KhademModel<TestUser> {
  late String? name;
  late String? email;
  late String? password;
  late bool? isActive;
  late DateTime? createdAt;
  late Map<String, dynamic>? settings;
  late List<String>? roles;
  late List<Map<String, dynamic>>? addresses;
  
  String get table => 'users';
  
  @override
  List<String> get fillable => [
    'name',
    'email',
    'password',
    'is_active',
    'created_at',
    'settings',
    'roles',
    'addresses',
  ];
  
  @override
  Map<String, dynamic> get casts => {
    'password': EncryptedCast(),
    'is_active': BoolCast(),
    'created_at': DateTimeCast(),
    'settings': JsonCast(),
    'roles': ArrayCast(),
    'addresses': JsonArrayCast(),
  };
  
  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'name':
        name = value;
        break;
      case 'email':
        email = value;
        break;
      case 'password':
        password = value;
        break;
      case 'is_active':
        isActive = value;
        break;
      case 'created_at':
        createdAt = value;
        break;
      case 'settings':
        settings = value;
        break;
      case 'roles':
        roles = value;
        break;
      case 'addresses':
        addresses = value;
        break;
    }
  }
  
  @override
  dynamic getField(String key) {
    try {
      switch (key) {
        case 'name':
          return name;
        case 'email':
          return email;
        case 'password':
          return password;
        case 'is_active':
          return isActive;
        case 'created_at':
          return createdAt;
        case 'settings':
          return settings;
        case 'roles':
          return roles;
        case 'addresses':
          return addresses;
        default:
          return null;
      }
    } catch (_) {
      // Handle uninitialized late fields
      return null;
    }
  }
  
  @override
  TestUser newFactory(Map<String, dynamic> data) => TestUser()..fromJson(data);
}

void main() {
  group('Model Integration with Casters', () {
    test('JsonCast integration - settings field', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'name': 'John Doe',
          'settings': '{"theme":"dark","language":"en"}',
        });
      
      expect(user.settings, isA<Map<String, dynamic>>());
      expect(user.settings!['theme'], equals('dark'));
      expect(user.settings!['language'], equals('en'));
    });
    
    test('ArrayCast integration - roles field', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'name': 'John Doe',
          'roles': '["admin","editor","user"]',
        });
      
      expect(user.roles, isA<List<String>>());
      expect(user.roles, hasLength(3));
      expect(user.roles![0], equals('admin'));
      expect(user.roles![1], equals('editor'));
    });
    
    test('JsonArrayCast integration - addresses field', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'name': 'John Doe',
          'addresses': '[{"street":"123 Main","city":"NYC"},{"street":"456 Oak","city":"LA"}]',
        });
      
      expect(user.addresses, isA<List<Map<String, dynamic>>>());
      expect(user.addresses, hasLength(2));
      expect(user.addresses![0]['city'], equals('NYC'));
      expect(user.addresses![1]['city'], equals('LA'));
    });
    
    test('BoolCast integration - isActive field', () {
      // Test with int
      final user1 = TestUser()
        ..fromJson({'id': 1, 'is_active': 1});
      expect(user1.isActive, isTrue);
      
      // Test with string
      final user2 = TestUser()
        ..fromJson({'id': 2, 'is_active': 'true'});
      expect(user2.isActive, isTrue);
      
      // Test with bool
      final user3 = TestUser()
        ..fromJson({'id': 3, 'is_active': false});
      expect(user3.isActive, isFalse);
    });
    
    test('DateTimeCast integration - createdAt field', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'created_at': '2024-10-09T12:00:00.000Z',
        });
      
      expect(user.createdAt, isA<DateTime>());
      expect(user.createdAt!.year, equals(2024));
      expect(user.createdAt!.month, equals(10));
    });
    
    test('EncryptedCast integration - password field (toDatabaseJson)', () {
      final user = TestUser()
        ..name = 'John'
        ..email = 'john@example.com'
        ..password = 'my_secret_password'
        ..isActive = true
        ..settings = {'theme': 'dark'}
        ..roles = ['admin']
        ..addresses = [{'city': 'NYC'}];
      
      final dbJson = user.toDatabaseJson();
      
      // Password should be hashed (64 chars for SHA-256)
      expect(dbJson['password'], isA<String>());
      expect(dbJson['password'].length, equals(64));
      expect(dbJson['password'], isNot(equals('my_secret_password')));
      
      // Settings should be JSON string
      expect(dbJson['settings'], isA<String>());
      expect(dbJson['settings'], contains('dark'));
      
      // Roles should be JSON array string
      expect(dbJson['roles'], isA<String>());
      expect(dbJson['roles'], contains('admin'));
      
      // Addresses should be JSON array string
      expect(dbJson['addresses'], isA<String>());
      expect(dbJson['addresses'], contains('NYC'));
    });
    
    test('Multiple casters work together', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'name': 'Jane Doe',
          'is_active': 1,
          'settings': '{"theme":"light","notifications":true}',
          'roles': '["user","moderator"]',
          'addresses': '[{"type":"home","city":"Boston"}]',
          'created_at': '2024-01-15T08:30:00.000Z',
        });
      
      // All casters should work
      expect(user.isActive, isTrue);
      expect(user.settings!['theme'], equals('light'));
      expect(user.roles, contains('moderator'));
      expect(user.addresses![0]['city'], equals('Boston'));
      expect(user.createdAt!.year, equals(2024));
    });
    
    test('Casters handle null values gracefully', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'name': 'Test',
          'settings': null,
          'roles': null,
          'addresses': null,
        });
      
      expect(user.settings, isNull);
      expect(user.roles, isNull);
      expect(user.addresses, isNull);
    });
    
    test('Legacy Type casts still work (backward compatibility)', () {
      // Create a model that uses old Type-based casts
      final model = LegacyModel()
        ..fromJson({
          'id': 1,
          'created_at': '2024-10-09T12:00:00.000Z',
          'count': '42',
          'price': '99.99',
          'active': 1,
        });
      
      expect(model.createdAt, isA<DateTime>());
      expect(model.count, equals(42));
      expect(model.price, equals(99.99));
      expect(model.active, isTrue);
    });
    
    test('Complex nested data with JsonArrayCast', () {
      final user = TestUser()
        ..fromJson({
          'id': 1,
          'addresses': '''
            [
              {
                "type": "home",
                "street": "123 Main St",
                "city": "NYC",
                "coordinates": {"lat": 40.7128, "lng": -74.0060}
              },
              {
                "type": "work",
                "street": "456 Office Blvd",
                "city": "SF",
                "coordinates": {"lat": 37.7749, "lng": -122.4194}
              }
            ]
          ''',
        });
      
      expect(user.addresses, hasLength(2));
      expect(user.addresses![0]['coordinates']['lat'], equals(40.7128));
      expect(user.addresses![1]['city'], equals('SF'));
    });
    
    test('Setting values directly uses casters on save', () {
      final user = TestUser()
        ..name = 'Direct Set Test'
        ..password = 'plain_password'
        ..settings = {'key': 'value'}
        ..roles = ['admin', 'user']
        ..addresses = [{'city': 'LA'}];
      
      final dbJson = user.toDatabaseJson();
      
      // Password hashed
      expect(dbJson['password'], isNot(equals('plain_password')));
      expect(dbJson['password'].length, equals(64));
      
      // Complex types converted to JSON strings
      expect(dbJson['settings'], isA<String>());
      expect(dbJson['roles'], isA<String>());
      expect(dbJson['addresses'], isA<String>());
    });
  });
}

/// Legacy model using old Type-based casts (backward compatibility test)
class LegacyModel extends KhademModel<LegacyModel> {
  late DateTime? createdAt;
  late int? count;
  late double? price;
  late bool? active;
  
  String get table => 'legacy';
  
  @override
  List<String> get fillable => ['created_at', 'count', 'price', 'active'];
  
  @override
  Map<String, dynamic> get casts => {
    'created_at': DateTime,
    'count': int,
    'price': double,
    'active': bool,
  };
  
  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'created_at':
        createdAt = value;
        break;
      case 'count':
        count = value;
        break;
      case 'price':
        price = value;
        break;
      case 'active':
        active = value;
        break;
    }
  }
  
  @override
  dynamic getField(String key) {
    switch (key) {
      case 'created_at':
        return createdAt;
      case 'count':
        return count;
      case 'price':
        return price;
      case 'active':
        return active;
      default:
        return null;
    }
  }
  
  @override
  LegacyModel newFactory(Map<String, dynamic> data) => LegacyModel()..fromJson(data);
}
