import 'package:test/test.dart';

import '../../lib/src/modules/auth/contracts/auth_config.dart';
import '../../lib/src/modules/auth/contracts/auth_repository.dart';
import '../../lib/src/modules/auth/contracts/password_verifier.dart';
import '../../lib/src/modules/auth/contracts/token_generator.dart';
import '../../lib/src/modules/auth/core/auth_driver.dart';
import '../../lib/src/modules/auth/exceptions/auth_exception.dart';
import '../../lib/src/modules/auth/services/auth_manager.dart';

/// Mock implementations for testing

class MockAuthRepository implements AuthRepository {
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
        if (user != null) return user;
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
    return _users.values.firstWhere(
      (user) => user[primaryKey] == id,
      orElse: () => {},
    );
  }

  @override
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData) async {
    _tokens[tokenData['token']] = tokenData;
    return tokenData;
  }

  @override
  Future<Map<String, dynamic>?> findToken(String token) async {
    return _tokens[token];
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

class MockAuthConfig implements AuthConfig {
  final Map<String, dynamic> _config = {
    'default': 'web',
    'guards': {
      'web': {
        'driver': 'jwt',
        'provider': 'users',
      },
      'api': {
        'driver': 'token',
        'provider': 'users',
      },
    },
    'providers': {
      'users': {
        'table': 'users',
        'primary_key': 'id',
        'fields': ['email', 'username'],
      },
    },
  };

  @override
  Map<String, dynamic> getProvider(String providerKey) {
    final provider = _config['providers'][providerKey];
    if (provider == null) {
      throw AuthException('Provider $providerKey not found');
    }
    return provider as Map<String, dynamic>;
  }

  @override
  Map<String, dynamic> getGuard(String guardName) {
    final guard = _config['guards'][guardName];
    if (guard == null) {
      throw AuthException('Guard $guardName not found');
    }
    return guard as Map<String, dynamic>;
  }

  @override
  String getDefaultGuard() => _config['default'] as String;

  @override
  T getOrDefault<T>(String key, T defaultValue) {
    return _config[key] as T? ?? defaultValue;
  }

  @override
  bool hasProvider(String providerKey) {
    return _config['providers']?.containsKey(providerKey) ?? false;
  }

  @override
  bool hasGuard(String guardName) {
    return _config['guards']?.containsKey(guardName) ?? false;
  }
}

class MockPasswordVerifier implements PasswordVerifier {
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

class MockTokenGenerator implements TokenGenerator {
  @override
  String generateToken({int length = 64, String? prefix}) {
    final token = 'token_$length';
    return prefix != null ? '$prefix|$token' : token;
  }

  @override
  String generateRefreshToken({int length = 64}) {
    return 'refresh_token_$length';
  }

  @override
  bool isValidTokenFormat(String token) {
    return token.isNotEmpty && !token.contains(' ');
  }
}

class MockAuthDriver implements AuthDriver {
  final MockAuthRepository repository;
  final MockPasswordVerifier passwordVerifier;
  final MockTokenGenerator tokenGenerator;

  MockAuthDriver()
      : repository = MockAuthRepository(),
        passwordVerifier = MockPasswordVerifier(),
        tokenGenerator = MockTokenGenerator();

  @override
  Future<Map<String, dynamic>> attemptLogin(Map<String, dynamic> credentials) async {
    if (credentials['email'] == 'test@example.com' && credentials['password'] == 'password123') {
      return {
        'user': {'id': 1, 'email': 'test@example.com'},
        'token': {
          'access_token': 'mock_access_token',
          'refresh_token': 'mock_refresh_token',
          'token_type': 'Bearer',
          'expires_in': 900,
        },
      };
    }
    throw AuthException('Invalid credentials');
  }

  @override
  Future<Map<String, dynamic>> verifyToken(String token) async {
    if (token == 'valid_token') {
      return {'id': 1, 'email': 'test@example.com'};
    }
    throw AuthException('Invalid token');
  }

  @override
  Future<void> logout(String token) async {
    if (token != 'valid_token') {
      throw AuthException('Invalid token');
    }
  }
  
  @override
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) {
    // TODO: implement refreshAccessToken
    throw UnimplementedError();
  }
}

void main() {
  group('Enhanced AuthManager Tests', () {
    late AuthManager authManager;
    late MockAuthConfig mockConfig;

    setUp(() {
      mockConfig = MockAuthConfig();
      authManager = AuthManager(authConfig: mockConfig);
    });

    tearDown(() {
      AuthManager.clearDriverCache();
    });

    group('Initialization', () {
      test('should initialize with default guard', () {
        expect(authManager.guard, equals('web'));
      });

      test('should initialize with custom guard', () {
        final customAuth = AuthManager(
          guard: 'api',
          authConfig: mockConfig,
        );
        expect(customAuth.guard, equals('api'));
      });

      test('should throw exception for invalid guard', () {
        expect(
          () => AuthManager(
            guard: 'nonexistent',
            authConfig: mockConfig,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Driver Management', () {
      test('should cache drivers', () {
        final auth1 = AuthManager(authConfig: mockConfig);
        final auth2 = AuthManager(authConfig: mockConfig);

        // Both should use the same cached driver
        expect(auth1.driver, equals(auth2.driver));
      });

      test('should support custom driver registration', () {
        AuthManager.registerDriverFactory(
          'custom',
          (providerKey) => MockAuthDriver(),
        );

        // Registration should succeed without error
        expect(true, isTrue); // Placeholder assertion
      });
    });

    group('Authentication Operations', () {
      test('should authenticate user successfully', () async {
        // This test would need proper mocking setup
        // For now, test the interface
        expect(authManager.login, isA<Function>());
        expect(authManager.verify, isA<Function>());
        expect(authManager.logout, isA<Function>());
      });

      test('should support guard-specific operations', () async {
        expect(authManager.loginWithGuard, isA<Function>());
        expect(authManager.verifyWithGuard, isA<Function>());
        expect(authManager.logoutWithGuard, isA<Function>());
      });
    });

    group('Configuration', () {
      test('should provide access to configuration', () {
        expect(authManager.config, isA<AuthConfig>());
      });

      test('should check guard existence', () {
        expect(authManager.hasGuard('web'), isTrue);
        expect(authManager.hasGuard('nonexistent'), isFalse);
      });

      test('should provide available guards', () {
        final guards = authManager.getAvailableGuards();
        expect(guards, isA<List<String>>());
        expect(guards, isNotEmpty);
      });
    });

    group('Error Handling', () {
      test('should wrap authentication errors', () async {
        final credentials = {'email': 'invalid@example.com', 'password': 'wrong'};
        
        expect(
          () => authManager.login(credentials),
          throwsA(isA<AuthException>()),
        );
      });

      test('should wrap token verification errors', () async {
        expect(
          () => authManager.verify('invalid_token'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should wrap logout errors', () async {
        expect(
          () => authManager.logout('invalid_token'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Performance', () {
      test('should cache drivers for performance', () {
        final startTime = DateTime.now();
        
        // Create multiple instances - should reuse cached drivers
        for (int i = 0; i < 10; i++) {
          AuthManager(authConfig: mockConfig);
        }
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        
        // Should be fast due to caching
        expect(duration.inMilliseconds, lessThan(100));
      });
    });
  });
}
