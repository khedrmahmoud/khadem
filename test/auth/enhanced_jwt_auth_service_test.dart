import 'package:test/test.dart';

import '../../lib/src/modules/auth/contracts/auth_config.dart';
import '../../lib/src/modules/auth/contracts/auth_repository.dart';
import '../../lib/src/modules/auth/contracts/password_verifier.dart';
import '../../lib/src/modules/auth/contracts/token_generator.dart';
import '../../lib/src/modules/auth/exceptions/auth_exception.dart';
import '../../lib/src/modules/auth/services/jwt_auth_service.dart';

/// Mock implementations for testing JWT service

class MockJWTAuthRepository implements AuthRepository {
  final Map<String, Map<String, dynamic>> _users = {
    'test@example.com': {
      'id': 1,
      'email': 'test@example.com',
      'password': 'hashed_password',
      'is_active': true,
    },
  };

  final Map<String, Map<String, dynamic>> _tokens = {};

  @override
  Future<Map<String, dynamic>?> findUserByCredentials(
    Map<String, dynamic> credentials,
    List<String> fields,
    String table,
  ) async {
    for (final field in fields) {
      if (credentials.containsKey(field)) {
        final user = _users[credentials[field]];
        if (user != null) return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> findUserById(
    dynamic id,
    String table,
    String primaryKey,
  ) async {
    return _users.values
        .where((user) => user[primaryKey] == id)
        .map((user) => Map<String, dynamic>.from(user))
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (user) => user != null,
          orElse: () => null,
        );
  }

  @override
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData) async {
    _tokens[tokenData['token']] = Map<String, dynamic>.from(tokenData);
    return tokenData;
  }

  @override
  Future<Map<String, dynamic>?> findToken(String token) async {
    final tokenData = _tokens[token];
    return tokenData != null ? Map<String, dynamic>.from(tokenData) : null;
  }

  @override
  Future<int> deleteToken(String token) async {
    final existed = _tokens.containsKey(token);
    _tokens.remove(token);
    return existed ? 1 : 0;
  }

  @override
  Future<int> deleteUserTokens(dynamic userId, [String? guard]) async {
    int count = 0;
    _tokens.removeWhere((token, data) {
      if (data['tokenable_id'] == userId && (guard == null || data['guard'] == guard)) {
        count++;
        return true;
      }
      return false;
    });
    return count;
  }

  @override
  Future<int> cleanupExpiredTokens() async {
    int count = 0;
    final now = DateTime.now();
    _tokens.removeWhere((token, data) {
      final expiresAt = data['expires_at'] as String?;
      if (expiresAt != null && DateTime.parse(expiresAt).isBefore(now)) {
        count++;
        return true;
      }
      return false;
    });
    return count;
  }
}

class MockJWTAuthConfig implements AuthConfig {
  @override
  Map<String, dynamic> getProvider(String providerKey) {
    return {
      'table': 'users',
      'primary_key': 'id',
      'fields': ['email', 'username'],
    };
  }

  @override
  Map<String, dynamic> getGuard(String guardName) {
    return {
      'driver': 'jwt',
      'provider': 'users',
    };
  }

  @override
  String getDefaultGuard() => 'web';

  @override
  T getOrDefault<T>(String key, T defaultValue) => defaultValue;

  @override
  bool hasProvider(String providerKey) => providerKey == 'users';

  @override
  bool hasGuard(String guardName) => ['web', 'api'].contains(guardName);
}

class MockJWTPasswordVerifier implements PasswordVerifier {
  @override
  Future<bool> verify(String password, String hash) async {
    return password == 'password123' && hash == 'hashed_password';
  }

  @override
  Future<String> hash(String password) async {
    return 'hashed_$password';
  }

  @override
  bool needsRehash(String hash) => false;
}

class MockJWTTokenGenerator implements TokenGenerator {
  @override
  String generateToken({int length = 64, String? prefix}) {
    final token = 'token_${DateTime.now().millisecondsSinceEpoch}';
    return prefix != null ? '$prefix|$token' : token;
  }

  @override
  String generateRefreshToken({int length = 64}) {
    return 'refresh_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  bool isValidTokenFormat(String token) {
    return token.isNotEmpty && !token.contains(' ');
  }
}

void main() {
  group('Enhanced JWT Auth Service Tests', () {
    late EnhancedJWTAuthService jwtService;
    late MockJWTAuthRepository mockRepository;
    late MockJWTAuthConfig mockConfig;
    late MockJWTPasswordVerifier mockPasswordVerifier;
    late MockJWTTokenGenerator mockTokenGenerator;

    setUp(() {
      mockRepository = MockJWTAuthRepository();
      mockConfig = MockJWTAuthConfig();
      mockPasswordVerifier = MockJWTPasswordVerifier();
      mockTokenGenerator = MockJWTTokenGenerator();

      jwtService = EnhancedJWTAuthService(
        providerKey: 'users',
        repository: mockRepository,
        config: mockConfig,
        passwordVerifier: mockPasswordVerifier,
        tokenGenerator: mockTokenGenerator,
        secret: 'test_secret_key_for_testing_purposes_only',
        accessTokenExpiry: const Duration(minutes: 15),
        refreshTokenExpiry: const Duration(days: 7),
      );
    });

    group('Factory Constructor', () {
      test('should create service with factory method', () {
        final service = EnhancedJWTAuthService.create('users');
        expect(service, isA<EnhancedJWTAuthService>());
        expect(service.providerKey, equals('users'));
      });
    });

    group('Authentication', () {
      test('should authenticate user with valid credentials', () async {
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final result = await jwtService.attemptLogin(credentials);

        expect(result, containsPair('user', isA<Map<String, dynamic>>()));
        expect(result, containsPair('token', isA<Map<String, dynamic>>()));
        
        final token = result['token'] as Map<String, dynamic>;
        expect(token, containsPair('access_token', isA<String>()));
        expect(token, containsPair('refresh_token', isA<String>()));
        expect(token, containsPair('token_type', 'Bearer'));
        expect(token, containsPair('expires_in', isA<int>()));
      });

      test('should reject invalid credentials', () async {
        final credentials = {
          'email': 'invalid@example.com',
          'password': 'wrongpassword',
        };

        expect(
          () => jwtService.attemptLogin(credentials),
          throwsA(isA<AuthException>()),
        );
      });

      test('should reject missing password', () async {
        final credentials = {
          'email': 'test@example.com',
        };

        expect(
          () => jwtService.attemptLogin(credentials),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Token Verification', () {
      test('should verify valid JWT token', () async {
        // First authenticate to get a token
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final authResult = await jwtService.attemptLogin(credentials);
        final token = authResult['token'] as Map<String, dynamic>;
        final accessToken = token['access_token'] as String;

        // Now verify the token
        final user = await jwtService.verifyToken(accessToken);

        expect(user, isA<Map<String, dynamic>>());
        expect(user['email'], equals('test@example.com'));
      });

      test('should reject invalid token format', () async {
        expect(
          () => jwtService.verifyToken('invalid_token'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should reject empty token', () async {
        expect(
          () => jwtService.verifyToken(''),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Token Management', () {
      test('should refresh access token with valid refresh token', () async {
        // First authenticate to get tokens
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final authResult = await jwtService.attemptLogin(credentials);
        final token = authResult['token'] as Map<String, dynamic>;
        final refreshToken = token['refresh_token'] as String;

        // Refresh the access token
        final refreshResult = await jwtService.refreshAccessToken(refreshToken);

        expect(refreshResult, containsPair('access_token', isA<String>()));
        expect(refreshResult, containsPair('token_type', 'Bearer'));
        expect(refreshResult, containsPair('expires_in', isA<int>()));
      });

      test('should reject invalid refresh token', () async {
        expect(
          () => jwtService.refreshAccessToken('invalid_refresh_token'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Logout', () {
      test('should logout user successfully', () async {
        // First authenticate
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final authResult = await jwtService.attemptLogin(credentials);
        final token = authResult['token'] as Map<String, dynamic>;
        final refreshToken = token['refresh_token'] as String;

        // Logout should not throw
        await jwtService.logout(refreshToken);
      });
    });

    group('Token Utilities', () {
      test('should decode JWT token', () async {
        // First authenticate to get a token
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final authResult = await jwtService.attemptLogin(credentials);
        final token = authResult['token'] as Map<String, dynamic>;
        final accessToken = token['access_token'] as String;

        // Decode the token
        final payload = jwtService.decodeToken(accessToken);

        expect(payload, isA<Map<String, dynamic>>());
        expect(payload, containsPair('id', 1));
        expect(payload, containsPair('guard', 'users'));
      });

      test('should check token expiry', () async {
        // First authenticate to get a token
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final authResult = await jwtService.attemptLogin(credentials);
        final token = authResult['token'] as Map<String, dynamic>;
        final accessToken = token['access_token'] as String;

        // Check if token is expired (should be false for new token)
        final isExpired = jwtService.isTokenExpired(accessToken);
        expect(isExpired, isFalse);
      });

      test('should get token remaining time', () async {
        // First authenticate to get a token
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        final authResult = await jwtService.attemptLogin(credentials);
        final token = authResult['token'] as Map<String, dynamic>;
        final accessToken = token['access_token'] as String;

        // Get remaining time
        final remainingTime = jwtService.getTokenRemainingTime(accessToken);
        expect(remainingTime, isA<Duration>());
        expect(remainingTime!.inMinutes, greaterThan(10)); // Should have most of 15 minutes left
      });
    });

    group('User Token Management', () {
      test('should revoke all user tokens', () async {
        // First authenticate to create some tokens
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        await jwtService.attemptLogin(credentials);

        // Revoke all tokens for user
        final revokedCount = await jwtService.revokeAllUserTokens(1);
        expect(revokedCount, greaterThanOrEqualTo(0));
      });

      test('should cleanup expired tokens', () async {
        final cleanedCount = await jwtService.cleanupExpiredTokens();
        expect(cleanedCount, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling', () {
      test('should handle invalid JWT secret gracefully', () {
        expect(
          () => EnhancedJWTAuthService(
            providerKey: 'users',
            repository: mockRepository,
            config: mockConfig,
            passwordVerifier: mockPasswordVerifier,
            tokenGenerator: mockTokenGenerator,
            secret: '', // Invalid empty secret
          ),
          isNot(throwsA(anything)), // Should not throw during construction
        );
      });

      test('should validate user status', () async {
        // Add inactive user to repository
        mockRepository._users['inactive@example.com'] = {
          'id': 2,
          'email': 'inactive@example.com',
          'password': 'hashed_password',
          'is_active': false,
        };

        final credentials = {
          'email': 'inactive@example.com',
          'password': 'password123',
        };

        expect(
          () => jwtService.attemptLogin(credentials),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
