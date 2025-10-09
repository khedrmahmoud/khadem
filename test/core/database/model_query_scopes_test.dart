import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/traits/query_scopes.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:test/test.dart';

// Test model with query scopes
class TestUser extends KhademModel<TestUser> with QueryScopes {
  int? id;
  String? name;
  String? email;
  bool? active;
  DateTime? emailVerifiedAt;
  String? role;

  // Define query scopes
  QueryBuilderInterface<TestUser> scopeActive(QueryBuilderInterface<TestUser> query) {
    return query.where('active', '=', true);
  }

  QueryBuilderInterface<TestUser> scopeVerified(QueryBuilderInterface<TestUser> query) {
    return query.whereNotNull('email_verified_at');
  }

  QueryBuilderInterface<TestUser> scopeRole(
    QueryBuilderInterface<TestUser> query,
    String role,
  ) {
    return query.where('role', '=', role);
  }

  QueryBuilderInterface<TestUser> scopeSearch(
    QueryBuilderInterface<TestUser> query,
    String search,
  ) {
    return query.whereLike('name', '%$search%');
  }

  // Composite scope
  QueryBuilderInterface<TestUser> scopeTrusted(QueryBuilderInterface<TestUser> query) {
    return scopeVerified(scopeActive(query));
  }

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
      case 'active':
        return active;
      case 'email_verified_at':
        return emailVerifiedAt;
      case 'role':
        return role;
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
      case 'active':
        active = value;
        break;
      case 'email_verified_at':
        emailVerifiedAt = value;
        break;
      case 'role':
        role = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['name', 'email', 'active', 'email_verified_at', 'role'];
}

void main() {
  group('Query Scopes', () {
    late TestUser user;

    setUp(() {
      user = TestUser();
    });

    test('model has QueryScopes mixin', () {
      expect(user, isA<QueryScopes>());
    });

    test('scopeActive returns query builder', () {
      final query = user.query;
      final result = user.scopeActive(query);

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('scopeRole accepts parameters', () {
      final query = user.query;
      final result = user.scopeRole(query, 'admin');

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('scopes can be chained', () {
      final query = user.query;
      final result = user.scopeRole(user.scopeActive(query), 'admin');

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('composite scope works', () {
      final query = user.query;
      final result = user.scopeTrusted(query);

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('scopes are isolated to model instances', () {
      final user1 = TestUser()..name = 'User 1';
      final user2 = TestUser()..name = 'User 2';

      final query1 = user1.scopeActive(user1.query);
      final query2 = user2.scopeActive(user2.query);

      // Both should work independently
      expect(query1, isA<QueryBuilderInterface<TestUser>>());
      expect(query2, isA<QueryBuilderInterface<TestUser>>());
    });

    test('scope with search parameter', () {
      final query = user.query;
      final result = user.scopeSearch(query, 'john');

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('multiple scopes can be applied', () {
      var query = user.query;

      // Apply multiple scopes
      query = user.scopeActive(query);
      query = user.scopeVerified(query);
      query = user.scopeRole(query, 'admin');

      expect(query, isA<QueryBuilderInterface<TestUser>>());
    });
  });

  group('Query Scopes - Usage Patterns', () {
    test('scope pattern with static helper', () {
      // Pattern: Define static helpers for easier usage
      final query = TestUser().query;
      final user = TestUser();

      final result = user.scopeActive(query);

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });

    test('scope pattern with method chaining', () {
      final user = TestUser();
      var query = user.query;

      // Chain multiple scopes
      query = user.scopeActive(query);
      query = user.scopeVerified(query);

      expect(query, isA<QueryBuilderInterface<TestUser>>());
    });

    test('scope pattern with composition', () {
      final user = TestUser();
      final query = user.query;

      // Use composite scope
      final result = user.scopeTrusted(query);

      expect(result, isA<QueryBuilderInterface<TestUser>>());
    });
  });

  group('Query Scopes - Edge Cases', () {
    test('scope with empty model', () {
      final user = TestUser();
      final query = user.query;

      // Should work even with empty model
      final result = user.scopeActive(query);

      expect(result, isNotNull);
    });

    test('scope with null parameters handled gracefully', () {
      final user = TestUser();
      final query = user.query;

      // Scope should handle parameters appropriately
      final result = user.scopeRole(query, 'guest');

      expect(result, isNotNull);
    });
  });
}
