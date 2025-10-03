import 'package:test/test.dart';
import 'package:khadem/src/modules/auth/core/auth_response.dart';

void main() {
  group('AuthResponse', () {
    test('should create response with all fields', () {
      final user = {'id': 1, 'email': 'test@example.com'};
      final response = AuthResponse(
        user: user,
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshExpiresIn: 86400,
        metadata: {'device': 'mobile'},
      );

      expect(response.user, equals(user));
      expect(response.accessToken, equals('access_token_123'));
      expect(response.refreshToken, equals('refresh_token_456'));
      expect(response.tokenType, equals('Bearer'));
      expect(response.expiresIn, equals(3600));
      expect(response.refreshExpiresIn, equals(86400));
      expect(response.metadata, equals({'device': 'mobile'}));
    });

    test('should create response with defaults', () {
      final user = {'id': 1, 'email': 'test@example.com'};
      final response = AuthResponse(user: user);

      expect(response.user, equals(user));
      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.tokenType, equals('Bearer'));
      expect(response.expiresIn, isNull);
      expect(response.refreshExpiresIn, isNull);
      expect(response.metadata, isNull);
    });

    test('should create from map', () {
      final map = {
        'user': {'id': 1, 'email': 'test@example.com'},
        'access_token': 'access_token_123',
        'refresh_token': 'refresh_token_456',
        'token_type': 'JWT',
        'expires_in': 3600,
        'refresh_expires_in': 86400,
        'metadata': {'device': 'web'},
      };

      final response = AuthResponse.fromJson(map);

      expect(response.user, equals({'id': 1, 'email': 'test@example.com'}));
      expect(response.accessToken, equals('access_token_123'));
      expect(response.refreshToken, equals('refresh_token_456'));
      expect(response.tokenType, equals('JWT'));
      expect(response.expiresIn, equals(3600));
      expect(response.refreshExpiresIn, equals(86400));
      expect(response.metadata, equals({'device': 'web'}));
    });

    test('should convert to map', () {
      final user = {'id': 1, 'email': 'test@example.com'};
      final response = AuthResponse(
        user: user,
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshExpiresIn: 86400,
        metadata: {'device': 'mobile'},
      );

      final map = response.toMap();

      expect(map['user'], equals(user));
      expect(map['access_token'], equals('access_token_123'));
      expect(map['refresh_token'], equals('refresh_token_456'));
      expect(map['token_type'], equals('Bearer'));
      expect(map['expires_in'], equals(3600));
      expect(map['refresh_expires_in'], equals(86400));
      expect(map['metadata'], equals({'device': 'mobile'}));
    });

    test('should create token-only response', () {
      final response = AuthResponse.tokenOnly(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        tokenType: 'JWT',
        expiresIn: 3600,
        refreshExpiresIn: 86400,
      );

      expect(response.user, equals({}));
      expect(response.accessToken, equals('access_token_123'));
      expect(response.refreshToken, equals('refresh_token_456'));
      expect(response.tokenType, equals('JWT'));
      expect(response.expiresIn, equals(3600));
      expect(response.refreshExpiresIn, equals(86400));
    });

    test('should create user-only response', () {
      final user = {'id': 1, 'email': 'test@example.com'};
      final response = AuthResponse.userOnly(user);

      expect(response.user, equals(user));
      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.tokenType, equals('Bearer'));
    });

    test('should check hasTokens correctly', () {
      final response1 = AuthResponse(user: {'id': 1});
      expect(response1.hasTokens, isFalse);

      final response2 = AuthResponse(user: {'id': 1}, accessToken: 'token');
      expect(response2.hasTokens, isTrue);

      final response3 = AuthResponse(user: {'id': 1}, refreshToken: 'token');
      expect(response3.hasTokens, isTrue);
    });

    test('should check hasUser correctly', () {
      final response1 = AuthResponse(user: {});
      expect(response1.hasUser, isFalse);

      final response2 = AuthResponse(user: {'id': 1});
      expect(response2.hasUser, isTrue);
    });

    test('should generate authorization header', () {
      final response1 = AuthResponse(user: {'id': 1});
      expect(response1.authorizationHeader, isNull);

      final response2 = AuthResponse(
        user: {'id': 1},
        accessToken: 'token123',
        tokenType: 'Bearer',
      );
      expect(response2.authorizationHeader, equals('Bearer token123'));

      final response3 = AuthResponse(
        user: {'id': 1},
        accessToken: 'token123',
        tokenType: 'JWT',
      );
      expect(response3.authorizationHeader, equals('JWT token123'));
    });

    test('should convert to string', () {
      final response = AuthResponse(
        user: {'id': 1, 'email': 'test@example.com'},
        accessToken: 'token123',
      );

      final string = response.toString();
      expect(string, contains('AuthResponse'));
      expect(string, contains('id, email'));
      expect(string, contains('hasTokens: true'));
    });
  });
}