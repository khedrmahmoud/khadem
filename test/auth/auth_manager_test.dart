import 'package:test/test.dart';

import '../../lib/src/modules/auth/services/auth_manager.dart';
import '../../lib/src/modules/auth/core/auth_driver.dart';

class MockAuthDriver implements AuthDriver {
  @override
  Future<Map<String, dynamic>> attemptLogin(Map<String, dynamic> credentials) async {
    if (credentials['email'] == 'test@example.com') {
      return {
        'token': 'mock_token_123',
        'user': {'id': 1, 'email': 'test@example.com'}
      };
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<Map<String, dynamic>> verifyToken(String token) async {
    if (token == 'valid_token') {
      return {'id': 1, 'email': 'test@example.com'};
    }
    throw Exception('Invalid token');
  }

  @override
  Future<void> logout(String token) async {
    if (token != 'valid_token') {
      throw Exception('Invalid token');
    }
  }
}

void main() {
  late AuthManager authManager;
  late MockAuthDriver mockDriver;

  setUp(() {
    mockDriver = MockAuthDriver();
    authManager = AuthManager();
  });

  group('AuthManager', () {
    group('Driver Management', () {
      test('should register and retrieve auth driver', () {
        authManager.registerDriver('test', mockDriver);

        expect(authManager.hasDriver('test'), isTrue);
        expect(authManager.getDriver('test'), equals(mockDriver));
      });

      test('should throw exception for unregistered driver', () {
        expect(
          () => authManager.getDriver('nonexistent'),
          throwsA(isA<Exception>()),
        );
      });

      test('should check if driver exists', () {
        expect(authManager.hasDriver('nonexistent'), isFalse);

        authManager.registerDriver('test', mockDriver);
        expect(authManager.hasDriver('test'), isTrue);
      });
    });

    group('Authentication Operations', () {
      setUp(() {
        authManager.registerDriver('test', mockDriver);
      });

      test('should successfully authenticate user', () async {
        final credentials = {'email': 'test@example.com', 'password': 'password123'};
        final result = await authManager.attempt('test', credentials);

        expect(result, contains('token'));
        expect(result['user'], isNotNull);
        expect(result['user']['email'], equals('test@example.com'));
      });

      test('should throw exception for invalid credentials', () async {
        final credentials = {'email': 'invalid@example.com', 'password': 'wrong'};

        expect(
          () => authManager.attempt('test', credentials),
          throwsA(isA<Exception>()),
        );
      });

      test('should verify token successfully', () async {
        final user = await authManager.verify('test', 'valid_token');

        expect(user, isNotNull);
        expect(user['email'], equals('test@example.com'));
      });

      test('should throw exception for invalid token', () async {
        expect(
          () => authManager.verify('test', 'invalid_token'),
          throwsA(isA<Exception>()),
        );
      });

      test('should logout user successfully', () async {
        await authManager.logout('test', 'valid_token');
        // Should not throw
      });

      test('should throw exception for logout with invalid token', () async {
        expect(
          () => authManager.logout('test', 'invalid_token'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Guard Management', () {
      test('should set and get default guard', () {
        authManager.setDefaultGuard('api');
        expect(authManager.getDefaultGuard(), equals('api'));
      });

      test('should use default guard when no guard specified', () async {
        authManager.registerDriver('default', mockDriver);
        authManager.setDefaultGuard('default');

        final credentials = {'email': 'test@example.com', 'password': 'password123'};
        final result = await authManager.attemptLogin(credentials);

        expect(result, contains('token'));
      });

      test('should throw exception when no default guard and no guard specified', () async {
        authManager.registerDriver('test', mockDriver);

        final credentials = {'email': 'test@example.com', 'password': 'password123'};

        expect(
          () => authManager.attemptLogin(credentials),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling', () {
      test('should throw exception for operations on non-existent guard', () async {
        final credentials = {'email': 'test@example.com', 'password': 'password123'};

        expect(
          () => authManager.attempt('nonexistent', credentials),
          throwsA(isA<Exception>()),
        );

        expect(
          () => authManager.verify('nonexistent', 'token'),
          throwsA(isA<Exception>()),
        );

        expect(
          () => authManager.logout('nonexistent', 'token'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
