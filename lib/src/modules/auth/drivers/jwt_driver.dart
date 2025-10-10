import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../contracts/auth_config.dart';
import '../contracts/authenticatable.dart';
import '../contracts/token_generator.dart';
import '../contracts/token_invalidation_strategy.dart';
import '../contracts/token_service.dart';
import '../core/auth_response.dart';
import '../core/database_authenticatable.dart';
import '../exceptions/auth_exception.dart';
import '../factories/token_invalidation_strategy_factory.dart';
import '../repositories/database_auth_repository.dart';
import '../services/database_token_service.dart';
import '../services/secure_token_generator.dart';
import 'auth_driver.dart';

/// JWT authentication driver
///
/// This driver handles JWT token generation, verification, and refresh
/// operations. It uses the dart_jsonwebtoken package for JWT operations.
/// 
/// Follows SOLID principles with dependency injection and strategy pattern.
class JWTDriver implements AuthDriver {
  /// JWT secret key
  final String _secret;

  /// Access token expiry duration
  final Duration _accessTokenExpiry;

  /// Refresh token expiry duration
  final Duration _refreshTokenExpiry;

  /// Token generator for refresh tokens
  final TokenGenerator _tokenGenerator;

  /// Token service for database operations
  final TokenService _tokenService;

  /// Strategy factory for token invalidation
  final TokenInvalidationStrategyFactory _strategyFactory;

  /// Auth config
  final AuthConfig _config;

  /// Provider key
  final String _providerKey;

  /// Creates a JWT driver with dependency injection
  JWTDriver({
    required String secret,
    required AuthConfig config, required String providerKey, Duration accessTokenExpiry = const Duration(hours: 1),
    Duration refreshTokenExpiry = const Duration(days: 7),
    TokenGenerator? tokenGenerator,
    TokenService? tokenService,
    TokenInvalidationStrategyFactory? strategyFactory,
  })  : _secret = secret,
        _accessTokenExpiry = accessTokenExpiry,
        _refreshTokenExpiry = refreshTokenExpiry,
        _tokenGenerator = tokenGenerator ?? SecureTokenGenerator(),
        _tokenService = tokenService ?? DatabaseTokenService(),
        _strategyFactory = strategyFactory ?? 
            TokenInvalidationStrategyFactory(
              tokenService ?? DatabaseTokenService(),
            ),
        _config = config,
        _providerKey = providerKey;

  /// Factory constructor with config and dependency injection
  factory JWTDriver.fromConfig(
    AuthConfig config, 
    String providerKey, {
    TokenGenerator? tokenGenerator,
    TokenService? tokenService,
    TokenInvalidationStrategyFactory? strategyFactory,
  }) {
    final provider = config.getProvider(providerKey);
    final secret = provider['jwt_secret'] as String?;

    if (secret == null || secret.isEmpty || secret == 'default-secret-key') {
      throw const FormatException(
        'JWT secret key must be configured and cannot be the default value. '
        'Please set a secure JWT secret in your auth configuration.',
      );
    }

    final accessExpiry = Duration(
      seconds: provider['access_token_expiry'] as int? ?? 3600,
    );

    final refreshExpiry = Duration(
      seconds: provider['refresh_token_expiry'] as int? ?? 604800,
    );

    // Create token service instance first to ensure it's not null
    late final TokenService tokenServiceInstance;
    try {
      tokenServiceInstance = tokenService ?? DatabaseTokenService();
    } catch (e) {
      throw StateError(
        'Failed to create TokenService: $e. '
        'Ensure database connection is initialized before creating auth driver.',
      );
    }

    // Create strategy factory with the guaranteed non-null service
    late final TokenInvalidationStrategyFactory strategyFactoryInstance;
    try {
      strategyFactoryInstance = strategyFactory ?? 
          TokenInvalidationStrategyFactory(tokenServiceInstance);
    } catch (e) {
      throw StateError(
        'Failed to create TokenInvalidationStrategyFactory: $e',
      );
    }

    return JWTDriver(
      secret: secret,
      accessTokenExpiry: accessExpiry,
      refreshTokenExpiry: refreshExpiry,
      tokenGenerator: tokenGenerator,
      tokenService: tokenServiceInstance,
      strategyFactory: strategyFactoryInstance,
      config: config,
      providerKey: providerKey,
    );
  }

  @override
  Future<AuthResponse> authenticate(
    Map<String, dynamic> credentials,
    Authenticatable user,
  ) async {
    return generateTokens(user);
  }

  @override
  Future<Authenticatable> verifyToken(String token) async {
    // First check if token is blacklisted
    if (await _tokenService.isTokenBlacklisted(token)) {
      throw AuthException('Token has been invalidated');
    }

    final jwt = JWT.verify(token, SecretKey(_secret));
    final payload = jwt.payload as Map<String, dynamic>;

    // Extract user data from JWT payload
    final userId = payload['sub'];
    final userData = payload['user'] as Map<String, dynamic>?;

    if (userId == null || userData == null) {
      throw AuthException('Invalid JWT payload');
    }

    // SECURITY: Always validate user still exists in database
    // This prevents access for deleted/deactivated users
    final provider = _config.getProvider(_providerKey);
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    // For user verification, we still need to access the repository directly
    // This could be improved by creating a UserService interface
    final repository = DatabaseAuthRepository();
    final currentUserData =
        await repository.findUserById(userId, table, primaryKey);
    if (currentUserData == null) {
      throw AuthException('User not found or deactivated');
    }

    // Create authenticatable from current database data, not JWT payload
    return DatabaseAuthenticatable.fromProviderConfig(
      currentUserData,
      provider,
    );
  }

  @override
  Future<AuthResponse> generateTokens(Authenticatable user) async {
    final now = DateTime.now();
    final userId = user.getAuthIdentifier();

    // Generate a unique session/correlation ID to link access and refresh tokens
    final sessionId = _tokenGenerator.generateToken(length: 32);

    // Create JWT payload - ensure 'sub' is always a string
    final payload = {
      'sub': userId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(_accessTokenExpiry).millisecondsSinceEpoch ~/ 1000,
      'jti': sessionId, // Use standard JWT ID claim for session correlation
      'user': _sanitizeUserData(user.toAuthArray()),
    };
    // Generate JWT
    final jwt = JWT(payload);
    final accessToken = jwt.sign(SecretKey(_secret));

    // Generate refresh token with embedded session ID
    // Format: <session_id>::<token> to enable correlation without schema changes
    final rawRefreshToken = _tokenGenerator.generateToken();
    final refreshToken = '$sessionId::$rawRefreshToken';

    // Store refresh token in database using injected service
    final refreshTokenData = {
      'token': refreshToken, // Contains session correlation in token format
      'tokenable_id': userId,
      'guard': _providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(_refreshTokenExpiry).toIso8601String(),
    };

    await _tokenService.storeToken(refreshTokenData);

    return AuthResponse(
      user: user.toAuthArray(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: _accessTokenExpiry.inSeconds,
      refreshExpiresIn: _refreshTokenExpiry.inSeconds,
    );
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    // Extract session ID and raw token from the combined refresh token
    final parts = refreshToken.split('::');
    if (parts.length != 2) {
      throw AuthException('Invalid refresh token format');
    }
    final sessionId = parts[0];
    
    // For JWT, verify the refresh token from database
    final tokenRecord = await _tokenService.findToken(refreshToken);

    if (tokenRecord == null) {
      throw AuthException('Invalid refresh token');
    }

    final tokenType = tokenRecord['type'] as String?;
    if (tokenType != 'refresh') {
      throw AuthException('Invalid token type for refresh');
    }

    // Check expiry
    final expiresAt = tokenRecord['expires_at'] as String?;
    if (expiresAt != null) {
      final expiry = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiry)) {
        await _tokenService.deleteToken(refreshToken);
        throw AuthException('Refresh token has expired');
      }
    }

    final userId = tokenRecord['tokenable_id'];

    // Get user data from database
    final provider = _config.getProvider(_providerKey);
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    // For user retrieval, we still need repository access
    // This could be improved with a UserService interface
    final repository = DatabaseAuthRepository();
    final userData = await repository.findUserById(userId, table, primaryKey);
    if (userData == null) {
      throw AuthException('User not found');
    }

    final user = DatabaseAuthenticatable.fromProviderConfig(
      userData,
      provider,
    );

    // Generate new access token reusing the same session ID
    final now = DateTime.now();
    final payload = {
      'sub': userId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(_accessTokenExpiry).millisecondsSinceEpoch ~/ 1000,
      'jti': sessionId, // Reuse the same session ID
      'user': _sanitizeUserData(user.toAuthArray()),
    };
    final jwt = JWT(payload);
    final newAccessToken = jwt.sign(SecretKey(_secret));

    // Generate new refresh token with the same session ID
    final rawRefreshToken = _tokenGenerator.generateToken();
    final newRefreshToken = '$sessionId::$rawRefreshToken';

    // Store new refresh token
    final refreshTokenData = {
      'token': newRefreshToken,
      'tokenable_id': userId,
      'guard': _providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(_refreshTokenExpiry).toIso8601String(),
    };

    await _tokenService.storeToken(refreshTokenData);

    // Clean up old refresh token
    await _tokenService.deleteToken(refreshToken);

    return AuthResponse(
      user: user.toAuthArray(),
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: _accessTokenExpiry.inSeconds,
      refreshExpiresIn: _refreshTokenExpiry.inSeconds,
    );
  }

  @override
  Future<void> invalidateToken(String token) async {
    // Use single device logout strategy by default
    final strategy = _strategyFactory.createStrategy(LogoutType.singleDevice);
    
    // Verify token to get context
    final jwt = JWT.verify(token, SecretKey(_secret));
    final payload = jwt.payload as Map<String, dynamic>;
    final exp = payload['exp'] as int?;
    final userId = payload['sub'];
    final sessionId = payload['jti'] as String?; // Use standard JWT ID claim
    
    if (exp != null && userId != null) {
      // For JWT single device logout, we need to find and invalidate the associated refresh token
      // This creates a true single device logout experience
      final context = TokenInvalidationContext.fromTokens(
        accessToken: token,
        userId: userId,
        guard: _providerKey,
        tokenExpiry: exp,
        tokenPayload: payload,
        metadata: sessionId != null ? {'session_id': sessionId} : null,
      );
      
      await strategy.invalidateTokens(context);
    }
  }

  /// Invalidates tokens using a specific strategy
  ///
  /// [token] The access token
  /// [logoutType] The type of logout strategy to use
  @override
  Future<void> invalidateTokenWithStrategy(String token, LogoutType logoutType) async {
    final strategy = _strategyFactory.createStrategy(logoutType);
    
    // Verify token to get context
    final jwt = JWT.verify(token, SecretKey(_secret));
    final payload = jwt.payload as Map<String, dynamic>;
    final exp = payload['exp'] as int?;
    final userId = payload['sub'];
    
    if (exp != null && userId != null) {
      final context = TokenInvalidationContext.fromTokens(
        accessToken: token,
        userId: userId,
        guard: _providerKey,
        tokenExpiry: exp,
        tokenPayload: payload,
      );
      
      await strategy.invalidateTokens(context);
    }
  }

  /// Invalidates all tokens for a user (logout from all devices)
  /// 
  /// This method should be called when a user wants to explicitly logout
  /// from all devices, such as when they change their password or suspect
  /// their account has been compromised.
  @override
  Future<void> logoutFromAllDevices(String token) async {
    await invalidateTokenWithStrategy(token, LogoutType.allDevices);
  }



  @override
  bool validateTokenFormat(String token) {
    // JWT format: header.payload.signature
    final parts = token.split('.');
    if (parts.length != 3) return false;

    // Check that each part is base64url encoded
    try {
      for (final part in parts) {
        // Simple check for base64url characters
        if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sanitizes user data to ensure all keys are strings and values are JSON serializable for JWT payload
  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> userData) {
    return userData.map((key, value) {
      // Ensure key is a string
      final stringKey = key.toString();

      // Sanitize value to be JSON serializable
      final sanitizedValue = _sanitizeValue(value);

      return MapEntry(stringKey, sanitizedValue);
    });
  }

  /// Sanitizes a value to ensure it's JSON serializable
  dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      return _sanitizeUserData(value as Map<String, dynamic>);
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is List) {
      return value.map(_sanitizeValue).toList();
    } else {
      // For other types, try to convert to string if not JSON serializable
      try {
        // Test if the value can be JSON encoded
        jsonEncode(value);
        return value;
      } catch (e) {
        // If not JSON serializable, convert to string
        return value.toString();
      }
    }
  }
}
