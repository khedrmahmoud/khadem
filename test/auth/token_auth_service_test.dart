import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/src/support/helpers/hash_helper.dart';
import '../../lib/src/modules/auth/exceptions/auth_exception.dart';
import '../../lib/src/modules/auth/services/token_auth_service.dart';

// Mock classes
class MockDatabase extends Mock {
  dynamic table(String name) => MockQueryBuilder();
}

class MockQueryBuilder extends Mock {
  Future<Map<String, dynamic>?> first() => Future.value(null);
  Future<void> insert(Map<String, dynamic> data) => Future.value();
  Future<void> delete() => Future.value();
  MockQueryBuilder where(String field, String operator, dynamic value) => this;
}

class MockConfig extends Mock {
  Map<String, dynamic>? section(String key) => null;
}

void main() {
  late TokenAuthService tokenAuthService;
  late MockDatabase mockDb;
  late MockConfig mockConfig;

  setUp(() {
    mockDb = MockDatabase();
    mockConfig = MockConfig();

    tokenAuthService = TokenAuthService(providerKey: 'users');
  });

  group('TokenAuthService', () {
    group('attemptLogin', () {
      test('should successfully authenticate user with valid credentials', () async {
        // Arrange
        final credentials = {'email': 'test@example.com', 'password': 'password123'};
        final user = {'id': 1, 'email': 'test@example.com', 'password': 'hashed_password'};
        final provider = {
          'table': 'users',
          'primary_key': 'id',
          'fields': ['email', 'username']
        };

        when(mockConfig.section('auth')).thenReturn({
          'providers': {'users': provider}
        });

        final mockQuery = MockQueryBuilder();
        when(mockDb.table('users')).thenReturn(mockQuery);
        when(mockQuery.where('email', '=', 'test@example.com')).thenReturn(mockQuery);
        when(mockQuery.first()).thenAnswer((_) => Future.value(user));

        // Mock password verification
        when(HashHelper.verify(any, any)).thenAnswer((_) async => true);

        final mockTokenQuery = MockQueryBuilder();
        when(mockDb.table('personal_access_tokens')).thenReturn(mockTokenQuery);
        when(mockTokenQuery.insert(any)).thenAnswer((_) async {});

        // Act
        final result = await tokenAuthService.attemptLogin(credentials);

        // Assert
        expect(result, contains('token'));
        expect(result['user'], equals(user));
        verify(mockTokenQuery.insert(any)).called(1);
      });

      test('should throw AuthException for invalid credentials', () async {
        // Arrange
        final credentials = {'email': 'invalid@example.com', 'password': 'wrong'};
        final provider = {
          'table': 'users',
          'primary_key': 'id',
          'fields': ['email', 'username']
        };

        when(mockConfig.section('auth')).thenReturn({
          'providers': {'users': provider}
        });

        final mockQuery = MockQueryBuilder();
        when(mockDb.table('users')).thenReturn(mockQuery);
        when(mockQuery.where('email', '=', 'invalid@example.com')).thenReturn(mockQuery);
        when(mockQuery.first()).thenAnswer((_) => Future.value(null));

        // Act & Assert
        expect(
          () => tokenAuthService.attemptLogin(credentials),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Invalid credentials')),
        );
      });

      test('should throw AuthException for missing auth configuration', () async {
        // Arrange
        when(mockConfig.section('auth')).thenReturn(null);

        // Act & Assert
        expect(
          () => tokenAuthService.attemptLogin({}),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Authentication configuration not found')),
        );
      });

      test('should throw AuthException for missing provider', () async {
        // Arrange
        when(mockConfig.section('auth')).thenReturn({
          'providers': {}
        });

        // Act & Assert
        expect(
          () => tokenAuthService.attemptLogin({}),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Authentication provider "users" not found')),
        );
      });
    });

    group('verifyToken', () {
      test('should successfully verify valid token', () async {
        // Arrange
        final token = 'valid_token_123';
        final tokenRecord = {'tokenable_id': 1};
        final user = {'id': 1, 'email': 'test@example.com'};
        final provider = {
          'table': 'users',
          'primary_key': 'id',
          'fields': ['email', 'username']
        };

        when(mockConfig.section('auth')).thenReturn({
          'providers': {'users': provider}
        });

        final mockTokenQuery = MockQueryBuilder();
        when(mockDb.table('personal_access_tokens')).thenReturn(mockTokenQuery);
        when(mockTokenQuery.where('token', '=', token)).thenReturn(mockTokenQuery);
        when(mockTokenQuery.first()).thenAnswer((_) => Future.value(tokenRecord));

        final mockUserQuery = MockQueryBuilder();
        when(mockDb.table('users')).thenReturn(mockUserQuery);
        when(mockUserQuery.where('id', '=', 1)).thenReturn(mockUserQuery);
        when(mockUserQuery.first()).thenAnswer((_) => Future.value(user));

        // Act
        final result = await tokenAuthService.verifyToken(token);

        // Assert
        expect(result, equals(user));
      });

      test('should throw AuthException for invalid token', () async {
        // Arrange
        final token = 'invalid_token';
        final provider = {
          'table': 'users',
          'primary_key': 'id',
          'fields': ['email', 'username']
        };

        when(mockConfig.section('auth')).thenReturn({
          'providers': {'users': provider}
        });

        final mockTokenQuery = MockQueryBuilder();
        when(mockDb.table('personal_access_tokens')).thenReturn(mockTokenQuery);
        when(mockTokenQuery.where('token', '=', token)).thenReturn(mockTokenQuery);
        when(mockTokenQuery.first()).thenAnswer((_) => Future.value(null));

        // Act & Assert
        expect(
          () => tokenAuthService.verifyToken(token),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Invalid token')),
        );
      });
    });

    group('logout', () {
      test('should successfully logout user', () async {
        // Arrange
        final token = 'token_to_logout';

        final mockTokenQuery = MockQueryBuilder();
        when(mockDb.table('personal_access_tokens')).thenReturn(mockTokenQuery);
        when(mockTokenQuery.where('token', '=', token)).thenReturn(mockTokenQuery);
        when(mockTokenQuery.delete()).thenAnswer((_) => Future.value());

        // Act
        await tokenAuthService.logout(token);

        // Assert
        verify(mockTokenQuery.delete()).called(1);
      });

      test('should throw AuthException on logout failure', () async {
        // Arrange
        final token = 'token_to_logout';

        final mockTokenQuery = MockQueryBuilder();
        when(mockDb.table('personal_access_tokens')).thenReturn(mockTokenQuery);
        when(mockTokenQuery.where('token', '=', token)).thenReturn(mockTokenQuery);
        when(mockTokenQuery.delete()).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => tokenAuthService.logout(token),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', startsWith('Logout failed:'))),
        );
      });
    });
  });
}
