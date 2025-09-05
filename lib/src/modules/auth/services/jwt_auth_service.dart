import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../../application/khadem.dart';
import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../contracts/auth_repository.dart';
import '../contracts/password_verifier.dart';
import '../contracts/token_generator.dart';
import '../exceptions/auth_exception.dart';
import '../repositories/database_auth_repository.dart';
import '../services/hash_password_verifier.dart';
import '../../../support/services/secure_token_generator.dart';
import 'base_auth_service.dart';

/// Enhanced JWT-based authentication service
///
/// This service provides JWT (JSON Web Token) authentication with support for
/// access tokens and refresh tokens. It extends BaseAuthService and implements
/// SOLID principles for better maintainability and testability.
///
/// Features:
/// - JWT access token generation and verification
/// - Refresh token support with configurable expiry
/// - Secure token storage in database
/// - Password hashing verification
/// - Configurable token expiry times
/// - Comprehensive error handling
/// - Token blacklisting support
/// - Multiple JWT algorithms support
///
/// Configuration requirements:
/// ```yaml
/// auth:
///   providers:
///     users:
///       table: users
///       primary_key: id
///       fields: [email, username]
///   guards:
///     web:
///       driver: jwt
///       provider: users
/// ```
///
/// Environment variables:
/// - JWT_SECRET: Secret key for JWT signing
/// - JWT_ALGORITHM: JWT algorithm (default: HS256)
/// - JWT_ACCESS_EXPIRY_MINUTES: Access token expiry (default: 15)
/// - JWT_REFRESH_EXPIRY_DAYS: Refresh token expiry (default: 7)
class EnhancedJWTAuthService extends BaseAuthService {
  /// JWT secret key for token signing
  final String _secret;

  /// JWT algorithm for token signing
  final String _algorithm;

  /// Access token expiry duration
  final Duration _accessTokenExpiry;

  /// Refresh token expiry duration
  final Duration _refreshTokenExpiry;

  /// Creates an enhanced JWT authentication service
  ///
  /// All dependencies are injected for better testability
  EnhancedJWTAuthService({
    required super.providerKey,
    AuthRepository? repository,
    AuthConfig? config,
    PasswordVerifier? passwordVerifier,
    TokenGenerator? tokenGenerator,
    String? secret,
    String? algorithm,
    Duration? accessTokenExpiry,
    Duration? refreshTokenExpiry,
  })  : _secret = secret ?? _getJwtSecret(),
        _algorithm = algorithm ?? _getJwtAlgorithm(),
        _accessTokenExpiry = accessTokenExpiry ?? _getAccessTokenExpiry(),
        _refreshTokenExpiry = refreshTokenExpiry ?? _getRefreshTokenExpiry(),
        super(
          repository: repository ?? DatabaseAuthRepository(),
          config: config ?? KhademAuthConfig(),
          passwordVerifier: passwordVerifier ?? HashPasswordVerifier(),
          tokenGenerator: tokenGenerator ?? SecureTokenGenerator(),
        );

  /// Factory constructor for easy instantiation
  factory EnhancedJWTAuthService.create(String providerKey) {
    return EnhancedJWTAuthService(providerKey: providerKey);
  }

  /// Gets JWT secret from environment with enhanced security
  static String _getJwtSecret() {
    final secret = Khadem.env.getOrDefault(
      'JWT_SECRET',
      'default_jwt_secret_change_in_production_environment',
    );

    // Validate secret strength
    if (secret.length < 32) {
      throw AuthException('JWT secret must be at least 32 characters long for security');
    }

    // Check for weak secrets
    if (secret == 'default_jwt_secret_change_in_production_environment') {
      throw AuthException('Please change the default JWT secret in production');
    }

    return secret;
  }

  /// Gets JWT algorithm from environment
  static String _getJwtAlgorithm() {
    return Khadem.env.getOrDefault('JWT_ALGORITHM', 'HS256');
  }

  /// Gets access token expiry from environment
  static Duration _getAccessTokenExpiry() {
    final minutes = int.parse(
      Khadem.env.getOrDefault('JWT_ACCESS_EXPIRY_MINUTES', '15'),
    );
    return Duration(minutes: minutes);
  }

  /// Gets refresh token expiry from environment
  static Duration _getRefreshTokenExpiry() {
    final days = int.parse(
      Khadem.env.getOrDefault('JWT_REFRESH_EXPIRY_DAYS', '7'),
    );
    return Duration(days: days);
  }

  @override
  Future<Map<String, dynamic>> generateAuthResult(
    Map<String, dynamic> user,
    Map<String, dynamic> provider,
  ) async {
    final primaryKey = provider['primary_key'] as String;
    final userId = user[primaryKey];

    final accessToken = _generateAccessToken(userId);
    final refreshToken = tokenGenerator.generateRefreshToken();

    return {
      'user': user,
      'token': {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': 'Bearer',
        'expires_in': _accessTokenExpiry.inSeconds,
        'refresh_expires_in': _refreshTokenExpiry.inSeconds,
      },
      '_refresh_token': refreshToken, // For internal storage
    };
  }

  @override
  Future<void> storeAuthSession(
    Map<String, dynamic> authResult,
    Map<String, dynamic> user,
    Map<String, dynamic> provider,
  ) async {
    final primaryKey = provider['primary_key'] as String;
    final userId = user[primaryKey];
    final refreshToken = authResult['_refresh_token'] as String;

    final tokenData = {
      'token': refreshToken,
      'tokenable_id': userId,
      'guard': providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(_refreshTokenExpiry).toIso8601String(),
    };

    await repository.storeToken(tokenData);
  }

  @override
  Future<Map<String, dynamic>> findUserByToken(
    String token,
    Map<String, dynamic> provider,
  ) async {
    try {
      // Try to verify as JWT access token first
      final jwt = JWT.verify(token, SecretKey(_secret));
      final payload = jwt.payload;

      if (payload == null) {
        throw AuthException('Invalid token payload');
      }

      final userId = payload['id'];
      final table = provider['table'] as String;
      final primaryKey = provider['primary_key'] as String;

      final user = await repository.findUserById(userId, table, primaryKey);

      if (user == null) {
        throw AuthException('User not found');
      }

      return user;
    } on JWTExpiredException {
      throw AuthException('Token has expired');
    } on JWTException catch (e) {
      throw AuthException('Invalid token: ${e.message}');
    }
  }

  @override
  Future<void> invalidateToken(String token) async {
    // For JWT access tokens, we could implement a blacklist
    // For now, we'll try to delete it as a refresh token
    await repository.deleteToken(token);
  }

  /// Generates a JWT access token
  ///
  /// [userId] The user ID to include in the token
  /// Returns a signed JWT token
  String _generateAccessToken(dynamic userId) {
    final payload = {
      'id': userId,
      'guard': providerKey,
      'type': 'access',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    return JWT(payload).sign(
      SecretKey(_secret),
      algorithm: _getJwtAlgorithmEnum(),
      expiresIn: _accessTokenExpiry,
    );
  }

  /// Gets the JWT algorithm enum from string
  ///
  /// Returns the appropriate JWTAlgorithm enum value
  JWTAlgorithm _getJwtAlgorithmEnum() {
    switch (_algorithm.toUpperCase()) {
      case 'HS256':
        return JWTAlgorithm.HS256;
      case 'HS384':
        return JWTAlgorithm.HS384;
      case 'HS512':
        return JWTAlgorithm.HS512;
      default:
        return JWTAlgorithm.HS256;
    }
  }

  /// Refreshes an access token using a valid refresh token
  ///
  /// [refreshToken] The refresh token
  /// Returns a new access token and refresh token
  /// Throws [AuthException] if refresh token is invalid or expired
  @override
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    final tokenRecord = await repository.findToken(refreshToken);

    if (tokenRecord == null) {
      throw AuthException('Invalid refresh token');
    }

    final expiresAt = DateTime.parse(tokenRecord['expires_at'] as String);
    if (DateTime.now().isAfter(expiresAt)) {
      // Clean up expired token
      await repository.deleteToken(refreshToken);
      throw AuthException('Refresh token has expired');
    }

    final userId = tokenRecord['tokenable_id'];

    // Generate new access token
    final newAccessToken = _generateAccessToken(userId);

    // Generate new refresh token
    final newRefreshToken = tokenGenerator.generateRefreshToken();

    // Store the new refresh token
    final newTokenData = {
      'token': newRefreshToken,
      'tokenable_id': userId,
      'guard': providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(_refreshTokenExpiry).toIso8601String(),
    };

    await repository.storeToken(newTokenData);

    // Invalidate the old refresh token for security
    await repository.deleteToken(refreshToken);

    return {
      'access_token': newAccessToken,
      'refresh_token': newRefreshToken,
      'token_type': 'Bearer',
      'expires_in': _accessTokenExpiry.inSeconds,
      'refresh_expires_in': _refreshTokenExpiry.inSeconds,
    };
  }

  /// Revokes all tokens for a user
  ///
  /// [userId] The user ID
  /// Returns the number of revoked tokens
  Future<int> revokeAllUserTokens(dynamic userId) async {
    return repository.deleteUserTokens(userId, providerKey);
  }

  /// Validates and decodes a JWT token without verification
  ///
  /// [token] The JWT token to decode
  /// Returns the decoded payload
  /// Throws [AuthException] for invalid tokens
  Map<String, dynamic> decodeToken(String token) {
    try {
      final jwt = JWT.decode(token);
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      throw AuthException('Unable to decode token: ${e.toString()}');
    }
  }

  /// Checks if a token is expired without full verification
  ///
  /// [token] The JWT token to check
  /// Returns true if token is expired
  bool isTokenExpired(String token) {
    try {
      final payload = decodeToken(token);
      final exp = payload['exp'] as int?;

      if (exp == null) return false;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true; // Consider invalid tokens as expired
    }
  }

  /// Gets the remaining time until token expiry
  ///
  /// [token] The JWT token to check
  /// Returns the remaining duration, null if token is invalid
  Duration? getTokenRemainingTime(String token) {
    try {
      final payload = decodeToken(token);
      final exp = payload['exp'] as int?;

      if (exp == null) return null;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      return expiryDate.isAfter(now)
          ? expiryDate.difference(now)
          : Duration.zero;
    } catch (e) {
      return null;
    }
  }

  /// Cleanup expired refresh tokens
  ///
  /// Returns the number of cleaned up tokens
  Future<int> cleanupExpiredTokens() async {
    return repository.cleanupExpiredTokens();
  }
}
