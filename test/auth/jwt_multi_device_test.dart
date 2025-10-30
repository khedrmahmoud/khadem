import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:khadem/src/modules/auth/contracts/auth_config.dart';
import 'package:khadem/src/modules/auth/contracts/token_service.dart';
import 'package:khadem/src/modules/auth/core/database_authenticatable.dart';
import 'package:khadem/src/modules/auth/drivers/jwt_driver.dart';
import 'package:test/test.dart';

// Mock token service for testing
class MockTokenService implements TokenService {
  final Map<String, Map<String, dynamic>> _tokens = {};
  final Map<String, List<Map<String, dynamic>>> _userTokens = {};

  @override
  Future<Map<String, dynamic>> storeToken(
      Map<String, dynamic> tokenData,) async {
    final token = tokenData['token'] as String;
    _tokens[token] = tokenData;

    final userId = tokenData['tokenable_id'];
    _userTokens.putIfAbsent(userId.toString(), () => []).add(tokenData);

    return tokenData;
  }

  @override
  Future<Map<String, dynamic>?> findToken(String token) async {
    return _tokens[token];
  }

  @override
  Future<List<Map<String, dynamic>>> findTokensByUser(dynamic userId,
      [String? guard,]) async {
    final tokens = _userTokens[userId.toString()] ?? [];
    if (guard != null) {
      return tokens.where((t) => t['guard'] == guard).toList();
    }
    return tokens;
  }

  Future<List<Map<String, dynamic>>> findTokensByPrefix(
      String tokenPrefix,) async {
    return _tokens.values
        .where((t) => (t['token'] as String).startsWith(tokenPrefix))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findTokensBySession(
    String sessionId, [
    String? guard,
    String? type,
  ]) async {
    // For JWT, tokens with session ID are in format: sessionId::randomToken
    return _tokens.values.where((tokenData) {
      final token = tokenData['token'] as String;
      final matchesSession = token.startsWith('$sessionId::');
      final matchesGuard = guard == null || tokenData['guard'] == guard;
      final matchesType = type == null || tokenData['type'] == type;
      return matchesSession && matchesGuard && matchesType;
    }).toList();
  }

  @override
  Future<int> invalidateSession(String sessionId, [String? guard]) async {
    final tokensToDelete = await findTokensBySession(sessionId, guard);
    int deleted = 0;

    for (final tokenData in tokensToDelete) {
      final token = tokenData['token'] as String;
      await deleteToken(token);
      deleted++;
    }

    return deleted;
  }

  @override
  Future<int> deleteToken(String token) async {
    final tokenData = _tokens.remove(token);
    if (tokenData != null) {
      final userId = tokenData['tokenable_id'];
      _userTokens[userId.toString()]?.removeWhere((t) => t['token'] == token);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteUserTokens(dynamic userId,
      {String? guard, Map<String, dynamic>? filter,}) async {
    final tokens = _userTokens[userId.toString()] ?? [];
    int deleted = 0;

    for (final tokenData in [...tokens]) {
      bool shouldDelete = true;

      // Check guard filter
      if (guard != null && tokenData['guard'] != guard) {
        shouldDelete = false;
      }

      // Check custom filters
      if (filter != null && shouldDelete) {
        for (final entry in filter.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List) {
            // For list values, check if the token's value is in the list
            if (!value.contains(tokenData[key])) {
              shouldDelete = false;
              break;
            }
          } else {
            // For single values, check for equality
            if (tokenData[key] != value) {
              shouldDelete = false;
              break;
            }
          }
        }
      }

      if (shouldDelete) {
        final token = tokenData['token'] as String;
        _tokens.remove(token);
        _userTokens[userId.toString()]?.remove(tokenData);
        deleted++;
      }
    }

    return deleted;
  }

  @override
  Future<int> cleanupExpiredTokens() async {
    return 0;
  }

  @override
  Future<Map<String, dynamic>> blacklistToken(
      Map<String, dynamic> tokenData,) async {
    return storeToken(tokenData);
  }

  @override
  Future<bool> isTokenBlacklisted(String token) async {
    final tokenRecord = await findToken(token);
    return tokenRecord != null && tokenRecord['type'] == 'blacklist';
  }
}

// Mock auth config for testing
class TestAuthConfig implements AuthConfig {
  @override
  Map<String, dynamic> getProvider(String providerKey) {
    return {
      'jwt_secret': 'test-secret-key-for-jwt-testing-purposes-only',
      'access_token_expiry': 3600, // 1 hour
      'refresh_token_expiry': 604800, // 7 days
      'table': 'users',
      'primary_key': 'id',
    };
  }

  @override
  List<Map<String, dynamic>> getProvidersForGuard(String guardName) =>
      [getProvider('users')];

  @override
  List<String> getAllProviderKeys() => ['users'];

  @override
  String getDefaultProvider() => 'users';

  @override
  Map<String, dynamic> getGuard(String guardName) => {};
  @override
  String getDefaultGuard() => 'api';
  @override
  T getOrDefault<T>(String key, T defaultValue) => defaultValue;
  @override
  bool hasProvider(String providerKey) => true;
  @override
  bool hasGuard(String guardName) => true;
}

void main() {
  group('JWT Multi-Device Authentication', () {
    late JWTDriver jwtDriver;
    late DatabaseAuthenticatable testUser;
    late MockTokenService mockTokenService;

    /// Helper to extract session ID from JWT token
    String? getSessionId(String token) {
      final jwt = JWT.verify(
        token,
        SecretKey('test-secret-key-for-jwt-testing-purposes-only'),
      );
      return jwt.payload['jti'] as String?;
    }

    /// Helper to extract session ID from refresh token
    String? getRefreshTokenSessionId(String token) {
      final parts = token.split('::');
      return parts.length == 2 ? parts[0] : null;
    }

    setUp(() {
      final authConfig = TestAuthConfig();
      mockTokenService = MockTokenService();

      jwtDriver = JWTDriver.fromConfig(
        authConfig,
        'users',
        tokenService: mockTokenService,
      );

      testUser = DatabaseAuthenticatable.fromProviderConfig(
        {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User',
        },
        authConfig.getProvider('users'),
      );
    });

    test('tokens maintain session correlation', () async {
      // Generate tokens for a device
      final tokens = await jwtDriver.generateTokens(testUser);

      // Extract session IDs
      final accessTokenSessionId = getSessionId(tokens.accessToken!);
      final refreshTokenSessionId =
          getRefreshTokenSessionId(tokens.refreshToken!);

      // Verify session correlation
      expect(accessTokenSessionId, isNotNull);
      expect(refreshTokenSessionId, isNotNull);
      expect(accessTokenSessionId, equals(refreshTokenSessionId));

      // Verify refresh token is stored with correct format
      final storedToken =
          await mockTokenService.findToken(tokens.refreshToken!);
      expect(storedToken, isNotNull);
      expect(storedToken!['type'], equals('refresh'));
      expect(storedToken['token'], startsWith('$accessTokenSessionId::'));
    });

    test('invalidateToken preserves refresh tokens for multi-device sessions',
        () async {
      // Generate tokens for device 1
      final device1Tokens = await jwtDriver.generateTokens(testUser);
      final device1SessionId = getSessionId(device1Tokens.accessToken!);

      // Generate tokens for device 2 (simulating another device)
      final device2Tokens = await jwtDriver.generateTokens(testUser);
      final device2SessionId = getSessionId(device2Tokens.accessToken!);

      // Verify different session IDs
      expect(device1SessionId, isNot(equals(device2SessionId)));

      // Logout from device 1 only (single device logout)
      await jwtDriver.invalidateToken(device1Tokens.accessToken!);

      // Device 1 access token should be blacklisted
      expect(
        await mockTokenService.isTokenBlacklisted(device1Tokens.accessToken!),
        isTrue,
      );

      // Device 2 access token should NOT be blacklisted
      expect(
        await mockTokenService.isTokenBlacklisted(device2Tokens.accessToken!),
        isFalse,
      );

      // Device 1 refresh token should be deleted
      final device1RefreshToken =
          await mockTokenService.findToken(device1Tokens.refreshToken!);
      expect(device1RefreshToken, isNull);

      // Device 2 refresh token should still exist
      final device2RefreshToken =
          await mockTokenService.findToken(device2Tokens.refreshToken!);
      expect(device2RefreshToken, isNotNull);
    });

    test('logoutFromAllDevices invalidates all tokens', () async {
      // Generate tokens for multiple devices
      final device1Tokens = await jwtDriver.generateTokens(testUser);
      final device2Tokens = await jwtDriver.generateTokens(testUser);
      final device3Tokens = await jwtDriver.generateTokens(testUser);

      // Verify tokens are stored
      expect(await mockTokenService.findToken(device1Tokens.refreshToken!),
          isNotNull,);
      expect(await mockTokenService.findToken(device2Tokens.refreshToken!),
          isNotNull,);
      expect(await mockTokenService.findToken(device3Tokens.refreshToken!),
          isNotNull,);

      // Logout from all devices
      await jwtDriver.logoutFromAllDevices(device1Tokens.accessToken!);

      // All access tokens should be blacklisted
      expect(
        await mockTokenService.isTokenBlacklisted(device1Tokens.accessToken!),
        isTrue,
      );

      // All refresh tokens should be deleted
      final userTokens = await mockTokenService.findTokensByUser(
          testUser.getAuthIdentifier(), 'users',);
      final refreshTokens =
          userTokens.where((t) => t['type'] == 'refresh').toList();
      expect(refreshTokens, isEmpty);
    });

    test(
        'invalidateToken with single device logout removes only the correlated refresh token',
        () async {
      // Generate tokens for multiple devices
      final device1Tokens = await jwtDriver.generateTokens(testUser);
      final device2Tokens = await jwtDriver.generateTokens(testUser);

      // Extract session IDs for verification
      final device1SessionId = getSessionId(device1Tokens.accessToken!);
      final device2SessionId = getSessionId(device2Tokens.accessToken!);

      // Verify we have different sessions for each device
      expect(device1SessionId, isNotNull);
      expect(device2SessionId, isNotNull);
      expect(device1SessionId, isNot(equals(device2SessionId)));

      // Verify refresh tokens have correct session correlation
      expect(getRefreshTokenSessionId(device1Tokens.refreshToken!),
          equals(device1SessionId),);
      expect(getRefreshTokenSessionId(device2Tokens.refreshToken!),
          equals(device2SessionId),);

      // Logout from device 1 using access token
      await jwtDriver.invalidateToken(device1Tokens.accessToken!);

      // Device 1 refresh token should be deleted (same session)
      final device1RefreshToken =
          await mockTokenService.findToken(device1Tokens.refreshToken!);
      expect(device1RefreshToken, isNull);

      // Device 2 refresh token should still exist (different session)
      final device2RefreshToken =
          await mockTokenService.findToken(device2Tokens.refreshToken!);
      expect(device2RefreshToken, isNotNull);

      // Device 1 access token should be blacklisted
      expect(
        await mockTokenService.isTokenBlacklisted(device1Tokens.accessToken!),
        isTrue,
      );

      // Device 2 access token should NOT be blacklisted
      expect(
        await mockTokenService.isTokenBlacklisted(device2Tokens.accessToken!),
        isFalse,
      );
    });
  });
}
