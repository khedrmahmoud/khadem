import 'package:test/test.dart';
import '../../lib/src/modules/auth/contracts/auth_config.dart';
import '../../lib/src/modules/auth/contracts/auth_repository.dart';
import '../../lib/src/modules/auth/contracts/password_verifier.dart';
import '../../lib/src/modules/auth/contracts/token_generator.dart';
import '../../lib/src/modules/auth/services/jwt_auth_service.dart';
import '../../lib/src/modules/auth/services/token_auth_service.dart';
import '../../lib/src/modules/auth/exceptions/auth_exception.dart';

/// Mock implementations for testing
class MockAuthRepository implements AuthRepository {
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _tokens = {};

  @override
  Future<Map<String, dynamic>?> findUserByCredentials(
    Map<String, dynamic> credentials,
    List<String> fields,
    String table,
  ) async {
    final email = credentials['email'] as String?;
    return _users.values.where((user) => user['email'] == email).firstOrNull;
  }

  @override
  Future<Map<String, dynamic>?> findUserById(
    dynamic id,
    String table,
    String primaryKey,
  ) async {
    return _users[id.toString()];
  }

  @override
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData) async {
    final token = tokenData['token'] as String;
    _tokens[token] = tokenData;
    return tokenData;
  }

  @override
  Future<Map<String, dynamic>?> findToken(String token) async {
    return _tokens[token];
  }

  @override
  Future<int> deleteToken(String token) async {
    return _tokens.remove(token) != null ? 1 : 0;
  }

  @override
  Future<int> deleteUserTokens(dynamic userId, [String? guard]) async {
    final tokensToRemove = <String>[];
    for (final entry in _tokens.entries) {
      if (entry.value['tokenable_id'] == userId) {
        tokensToRemove.add(entry.key);
      }
    }
    
    for (final token in tokensToRemove) {
      _tokens.remove(token);
    }
    
    return tokensToRemove.length;
  }

  @override
  Future<int> cleanupExpiredTokens() async {
    final now = DateTime.now();
    final tokensToRemove = <String>[];
    
    for (final entry in _tokens.entries) {
      final expiresAt = entry.value['expires_at'] as String?;
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (now.isAfter(expiry)) {
          tokensToRemove.add(entry.key);
        }
      }
    }
    
    for (final token in tokensToRemove) {
      _tokens.remove(token);
    }
    
    return tokensToRemove.length;
  }

  void addTestUser(String id, Map<String, dynamic> userData) {
    _users[id] = {
      'id': id,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      ...userData,
    };
  }

  void clear() {
    _users.clear();
    _tokens.clear();
  }
}

class MockAuthConfig implements AuthConfig {
  final Map<String, dynamic> _guards = {
    'web': {'driver': 'jwt', 'provider': 'users'},
    'api': {'driver': 'token', 'provider': 'users'},
  };

  final Map<String, dynamic> _providers = {
    'users': {
      'driver': 'database',
      'table': 'users',
      'primary_key': 'id',
      'fields': ['email', 'username'],
    },
  };

  @override
  Map<String, dynamic> getProvider(String providerKey) {
    if (!_providers.containsKey(providerKey)) {
      throw Exception('Provider not found: $providerKey');
    }
    return _providers[providerKey]!;
  }

  @override
  Map<String, dynamic> getGuard(String guardName) {
    if (!_guards.containsKey(guardName)) {
      throw Exception('Guard not found: $guardName');
    }
    return _guards[guardName]!;
  }

  @override
  String getDefaultGuard() => 'web';

  @override
  T getOrDefault<T>(String key, T defaultValue) {
    // Simple implementation for testing
    switch (key) {
      case 'JWT_SECRET':
        return 'test-secret' as T;
      case 'JWT_ALGORITHM':
        return 'HS256' as T;
      case 'JWT_ACCESS_EXPIRY_MINUTES':
        return '15' as T;
      case 'JWT_REFRESH_EXPIRY_DAYS':
        return '7' as T;
      default:
        return defaultValue;
    }
  }

  @override
  bool hasProvider(String providerKey) {
    return _providers.containsKey(providerKey);
  }

  @override
  bool hasGuard(String guardName) {
    return _guards.containsKey(guardName);
  }
}

class MockPasswordVerifier implements PasswordVerifier {
  @override
  Future<String> hash(String password) async {
    return 'hashed_$password';
  }

  @override
  Future<bool> verify(String password, String hashedPassword) async {
    return hashedPassword == 'hashed_$password';
  }

  @override
  bool needsRehash(String hash) {
    return false; // For testing, assume no rehashing needed
  }
}

class MockTokenGenerator implements TokenGenerator {
  int _counter = 1;

  @override
  String generateToken({int length = 64, String? prefix}) {
    return '${prefix ?? ''}token_${_counter++}_${'x' * (length - 10)}';
  }

  @override
  String generateRefreshToken({int length = 64}) {
    return 'refresh_token_${_counter++}_${'x' * (length - 15)}';
  }

  @override
  bool isValidTokenFormat(String token) {
    return token.isNotEmpty && token.length >= 10;
  }

  void reset() {
    _counter = 1;
  }
}

void main() {
  group('RefreshAccessToken Functionality', () {
    late MockAuthRepository mockRepository;
    late MockAuthConfig mockConfig;
    late MockPasswordVerifier mockPasswordVerifier;
    late MockTokenGenerator mockTokenGenerator;

    setUp(() {
      mockRepository = MockAuthRepository();
      mockConfig = MockAuthConfig();
      mockPasswordVerifier = MockPasswordVerifier();
      mockTokenGenerator = MockTokenGenerator();
    });

    tearDown(() {
      mockRepository.clear();
      mockTokenGenerator.reset();
    });

    group('JWT Auth Service - refreshAccessToken', () {
      late EnhancedJWTAuthService jwtService;

      setUp(() {
        jwtService = EnhancedJWTAuthService(
          providerKey: 'users',
          repository: mockRepository,
          config: mockConfig,
          passwordVerifier: mockPasswordVerifier,
          tokenGenerator: mockTokenGenerator,
          secret: 'test-secret-key-for-jwt',
          accessTokenExpiry: const Duration(minutes: 15),
          refreshTokenExpiry: const Duration(days: 7),
        );
      });

      test('should refresh access token with valid refresh token', () async {
        // Arrange
        mockRepository.addTestUser('1', {
          'email': 'test@example.com',
          'password': 'hashed_password123',
        });

        // Create a valid refresh token
        const refreshToken = 'valid_refresh_token';
        await mockRepository.storeToken({
          'token': refreshToken,
          'tokenable_id': '1',
          'guard': 'users',
          'type': 'refresh',
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        });

        // Act
        final result = await jwtService.refreshAccessToken(refreshToken);

        // Assert
        expect(result['access_token'], isNotNull);
        expect(result['token_type'], equals('Bearer'));
        expect(result['expires_in'], equals(15 * 60)); // 15 minutes in seconds
        expect(result['refresh_token'], equals(refreshToken));
        expect(result['refresh_expires_in'], greaterThan(0));
      });

      test('should fail refresh with invalid refresh token', () async {
        // Act & Assert
        expect(
          () => jwtService.refreshAccessToken('invalid_token'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should fail refresh with expired refresh token', () async {
        // Arrange
        final expiredRefreshToken = 'expired_refresh_token';
        await mockRepository.storeToken({
          'token': expiredRefreshToken,
          'tokenable_id': '1',
          'guard': 'users',
          'type': 'refresh',
          'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
          'expires_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        });

        // Act & Assert
        expect(
          () => jwtService.refreshAccessToken(expiredRefreshToken),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Token Auth Service - refreshAccessToken', () {
      late EnhancedTokenAuthService tokenService;

      setUp(() {
        tokenService = EnhancedTokenAuthService(
          providerKey: 'users',
          repository: mockRepository,
          config: mockConfig,
          passwordVerifier: mockPasswordVerifier,
          tokenGenerator: mockTokenGenerator,
          tokenExpiry: const Duration(hours: 24),
        );
      });

      test('should refresh access token with valid refresh token', () async {
        // Arrange
        mockRepository.addTestUser('1', {
          'email': 'test@example.com',
          'password': 'hashed_password123',
        });

        // Create a valid refresh token
        final refreshToken = 'valid_refresh_token';
        await mockRepository.storeToken({
          'token': refreshToken,
          'tokenable_id': '1',
          'guard': 'users',
          'type': 'refresh',
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        });

        // Act
        final result = await tokenService.refreshAccessToken(refreshToken);

        // Assert
        expect(result['access_token'], isNotNull);
        expect(result['token_type'], equals('Bearer'));
        expect(result['expires_in'], equals(24 * 60 * 60)); // 24 hours in seconds
        expect(result['refresh_token'], equals(refreshToken));
      });

      test('should refresh access token with access token (fallback)', () async {
        // Arrange
        mockRepository.addTestUser('1', {
          'email': 'test@example.com',
          'password': 'hashed_password123',
        });

        // Create a valid access token (should also work as refresh for simple tokens)
        final accessToken = 'valid_access_token';
        await mockRepository.storeToken({
          'token': accessToken,
          'tokenable_id': '1',
          'guard': 'users',
          'type': 'access',
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        });

        // Act
        final result = await tokenService.refreshAccessToken(accessToken);

        // Assert
        expect(result['access_token'], isNotNull);
        expect(result['token_type'], equals('Bearer'));
        expect(result['refresh_token'], equals(accessToken));
      });

      test('should fail refresh with invalid token type', () async {
        // Arrange
        final apiToken = 'api_token';
        await mockRepository.storeToken({
          'token': apiToken,
          'tokenable_id': '1',
          'guard': 'users',
          'type': 'api',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Act & Assert
        expect(
          () => tokenService.refreshAccessToken(apiToken),
          throwsA(isA<AuthException>()),
        );
      });

      test('should fail refresh with expired token', () async {
        // Arrange
        final expiredToken = 'expired_token';
        await mockRepository.storeToken({
          'token': expiredToken,
          'tokenable_id': '1',
          'guard': 'users',
          'type': 'refresh',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'expires_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        });

        // Act & Assert
        expect(
          () => tokenService.refreshAccessToken(expiredToken),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Cross-Service Compatibility', () {
      test('both services should implement refreshAccessToken method', () {
        final jwtService = EnhancedJWTAuthService(
          providerKey: 'users',
          repository: mockRepository,
          config: mockConfig,
          passwordVerifier: mockPasswordVerifier,
          tokenGenerator: mockTokenGenerator,
        );

        final tokenService = EnhancedTokenAuthService(
          providerKey: 'users',
          repository: mockRepository,
          config: mockConfig,
          passwordVerifier: mockPasswordVerifier,
          tokenGenerator: mockTokenGenerator,
        );

        // Both services should have the refreshAccessToken method
        expect(jwtService.refreshAccessToken, isA<Function>());
        expect(tokenService.refreshAccessToken, isA<Function>());
      });
    });
  });
}
