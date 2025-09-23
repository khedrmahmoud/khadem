import 'package:khadem/src/core/http/request/request_auth.dart';
import 'package:test/test.dart';

void main() {
  group('RequestAuth', () {
    late RequestAuth auth;

    setUp(() {
      auth = RequestAuth({});
    });

    group('User Management', () {
      test('should set and get user', () {
        final userData = {'id': 1, 'name': 'John', 'email': 'john@example.com'};
        auth.setUser(userData);

        expect(auth.user, equals(userData));
        expect(auth.isAuthenticated, isTrue);
        expect(auth.isGuest, isFalse);
      });

      test('should get user ID', () {
        final userData = {'id': 123, 'name': 'John'};
        auth.setUser(userData);

        expect(auth.userId, equals(123));
      });

      test('should handle user without ID', () {
        final userData = {'name': 'John', 'email': 'john@example.com'};
        auth.setUser(userData);

        expect(auth.userId, isNull);
      });

      test('should handle null user ID', () {
        final userData = {'id': null, 'name': 'John'};
        auth.setUser(userData);

        expect(auth.userId, isNull);
      });

      test('should clear user', () {
        auth.setUser({'id': 1, 'name': 'John'});
        expect(auth.isAuthenticated, isTrue);

        auth.clearUser();
        expect(auth.isAuthenticated, isFalse);
        expect(auth.user, isNull);
        expect(auth.userId, isNull);
      });

      test('should handle guest state', () {
        expect(auth.isAuthenticated, isFalse);
        expect(auth.isGuest, isTrue);
        expect(auth.user, isNull);
        expect(auth.userId, isNull);
      });
    });

    group('Role Management', () {
      test('should check single role', () {
        final userData = {
          'id': 1,
          'name': 'John',
          'roles': ['admin', 'user', 'moderator'],
        };
        auth.setUser(userData);

        expect(auth.hasRole('admin'), isTrue);
        expect(auth.hasRole('user'), isTrue);
        expect(auth.hasRole('moderator'), isTrue);
        expect(auth.hasRole('superuser'), isFalse);
      });

      test('should check multiple roles (any)', () {
        final userData = {
          'id': 1,
          'name': 'John',
          'roles': ['user', 'moderator'],
        };
        auth.setUser(userData);

        expect(auth.hasAnyRole(['admin', 'user']), isTrue);
        expect(auth.hasAnyRole(['admin', 'superuser']), isFalse);
        expect(auth.hasAnyRole([]), isFalse);
      });

      test('should check multiple roles (all)', () {
        final userData = {
          'id': 1,
          'name': 'John',
          'roles': ['admin', 'user', 'moderator'],
        };
        auth.setUser(userData);

        expect(auth.hasAllRoles(['admin', 'user']), isTrue);
        expect(auth.hasAllRoles(['admin', 'superuser']), isFalse);
        expect(auth.hasAllRoles([]), isTrue);
      });

      test('should handle user without roles', () {
        final userData = {'id': 1, 'name': 'John'};
        auth.setUser(userData);

        expect(auth.hasRole('admin'), isFalse);
        expect(auth.hasAnyRole(['admin', 'user']), isFalse);
        expect(auth.hasAllRoles(['admin', 'user']), isFalse);
      });

      test('should handle null roles', () {
        final userData = {'id': 1, 'name': 'John', 'roles': null};
        auth.setUser(userData);

        expect(auth.hasRole('admin'), isFalse);
        expect(auth.hasAnyRole(['admin']), isFalse);
        expect(auth.hasAllRoles(['admin']), isFalse);
      });

      test('should handle non-list roles', () {
        final userData = {'id': 1, 'name': 'John', 'roles': 'admin'};
        auth.setUser(userData);

        expect(auth.hasRole('admin'), isFalse);
        expect(auth.hasAnyRole(['admin']), isFalse);
        expect(auth.hasAllRoles(['admin']), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty user data', () {
        auth.setUser({});

        expect(auth.user, equals({}));
        expect(auth.isAuthenticated, isTrue);
        expect(auth.userId, isNull);
        expect(auth.hasRole('admin'), isFalse);
      });

      test('should handle numeric user ID', () {
        final userData = {'id': 123, 'name': 'John'};
        auth.setUser(userData);

        expect(auth.userId, equals(123));
      });

      test('should handle string user ID', () {
        final userData = {'id': 'user123', 'name': 'John'};
        auth.setUser(userData);

        expect(auth.userId, equals('user123'));
      });
    });
  });
}
