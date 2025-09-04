import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../contracts/auth_repository.dart';
import '../contracts/password_verifier.dart';
import '../contracts/token_generator.dart';
import '../exceptions/auth_exception.dart';
import '../repositories/database_auth_repository.dart';
import '../services/hash_password_verifier.dart';
import '../services/secure_token_generator.dart';
import 'base_auth_service.dart';

/// Enhanced Token-based authentication service
///
/// This service provides simple token-based authentication without JWT complexity.
/// It generates secure random tokens for user sessions and stores them in the database.
/// It extends BaseAuthService and implements SOLID principles for better maintainability.
///
/// Features:
/// - Secure random token generation
/// - Database-backed token storage
/// - Password hashing verification
/// - Simple token validation
/// - Automatic token cleanup
/// - Token expiry support
/// - Multiple token types (access, refresh, API)
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
///     api:
///       driver: token
///       provider: users
/// ```
class EnhancedTokenAuthService extends BaseAuthService {
  /// Token expiry duration (if configured)
  final Duration? _tokenExpiry;

  /// Creates an enhanced token authentication service
  ///
  /// All dependencies are injected for better testability
  EnhancedTokenAuthService({
    required super.providerKey,
    AuthRepository? repository,
    AuthConfig? config,
    PasswordVerifier? passwordVerifier,
    TokenGenerator? tokenGenerator,
    Duration? tokenExpiry,
  })  : _tokenExpiry = tokenExpiry,
        super(
          repository: repository ?? DatabaseAuthRepository(),
          config: config ?? KhademAuthConfig(),
          passwordVerifier: passwordVerifier ?? HashPasswordVerifier(),
          tokenGenerator: tokenGenerator ?? SecureTokenGenerator(),
        );

  /// Factory constructor for easy instantiation
  factory EnhancedTokenAuthService.create(String providerKey) {
    return EnhancedTokenAuthService(providerKey: providerKey);
  }

  @override
  Future<Map<String, dynamic>> generateAuthResult(
    Map<String, dynamic> user,
    Map<String, dynamic> provider,
  ) async {
    final primaryKey = provider['primary_key'] as String;
    final userId = user[primaryKey];

    final accessToken = tokenGenerator.generateToken(
      prefix: userId.toString(),
    );

    return {
      'user': user,
      'token': accessToken,
      'token_type': 'Bearer',
      'expires_in': _tokenExpiry?.inSeconds,
      '_access_token': accessToken, // For internal storage
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
    final accessToken = authResult['_access_token'] as String;

    final tokenData = {
      'token': accessToken,
      'tokenable_id': userId,
      'guard': providerKey,
      'type': 'access',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Add expiry if configured
    if (_tokenExpiry != null) {
      tokenData['expires_at'] =
          DateTime.now().add(_tokenExpiry!).toIso8601String();
    }

    await repository.storeToken(tokenData);
  }

  @override
  Future<Map<String, dynamic>> findUserByToken(
    String token,
    Map<String, dynamic> provider,
  ) async {
    final tokenRecord = await repository.findToken(token);

    if (tokenRecord == null) {
      throw AuthException('Invalid token');
    }

    // Check token expiry if configured
    final expiresAt = tokenRecord['expires_at'] as String?;
    if (expiresAt != null) {
      final expiry = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiry)) {
        // Clean up expired token
        await repository.deleteToken(token);
        throw AuthException('Token has expired');
      }
    }

    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;
    final userId = tokenRecord['tokenable_id'];

    final user = await repository.findUserById(userId, table, primaryKey);

    if (user == null) {
      throw AuthException('User not found');
    }

    return user;
  }

  @override
  Future<void> invalidateToken(String token) async {
    await repository.deleteToken(token);
  }

  /// Generates an API token for long-term access
  ///
  /// [user] The user to generate token for
  /// [name] Optional name for the token
  /// [expiresAt] Optional expiry date
  /// Returns the API token data
  Future<Map<String, dynamic>> generateApiToken(
    Map<String, dynamic> user, {
    String? name,
    DateTime? expiresAt,
  }) async {
    final provider = config.getProvider(providerKey);
    final primaryKey = provider['primary_key'] as String;
    final userId = user[primaryKey];

    final token = tokenGenerator.generateToken(length: 80);

    final tokenData = {
      'token': token,
      'tokenable_id': userId,
      'guard': providerKey,
      'type': 'api',
      'name': name ?? 'API Token',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (expiresAt != null) {
      tokenData['expires_at'] = expiresAt.toIso8601String();
    }

    await repository.storeToken(tokenData);

    return {
      'token': token,
      'name': name ?? 'API Token',
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Revokes all tokens for a user
  ///
  /// [userId] The user ID
  /// Returns the number of revoked tokens
  Future<int> revokeAllUserTokens(dynamic userId) async {
    return repository.deleteUserTokens(userId, providerKey);
  }

  /// Lists all active tokens for a user
  ///
  /// [userId] The user ID
  /// Returns a list of token information (without the actual tokens)
  Future<List<Map<String, dynamic>>> getUserTokens(dynamic userId) async {
    // This would require additional repository method
    // For now, return empty list as placeholder
    return [];
  }

  /// Revokes a specific token by its value
  ///
  /// [token] The token to revoke
  /// Returns true if token was found and revoked
  Future<bool> revokeToken(String token) async {
    final deletedCount = await repository.deleteToken(token);
    return deletedCount > 0;
  }

  /// Updates token's last used timestamp
  ///
  /// [token] The token that was used
  Future<void> updateTokenLastUsed(String token) async {
    // This would require additional repository method
    // For now, this is a placeholder for the functionality
  }

  /// Validates token format and structure
  @override
  Future<void> validateToken(String token) async {
    await super.validateToken(token);

    // Additional token-specific validation
    if (token.length < 32) {
      throw AuthException('Token too short');
    }
  }

  /// Refreshes an access token using a refresh token
  ///
  /// For simple token authentication, this generates both a new access token
  /// and a new refresh token, then invalidates the old refresh token for security
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

    // Check if it's actually a refresh token
    final tokenType = tokenRecord['type'] as String?;
    if (tokenType != 'refresh' && tokenType != 'access') {
      throw AuthException('Invalid token type for refresh');
    }

    // Check token expiry if configured
    final expiresAt = tokenRecord['expires_at'] as String?;
    if (expiresAt != null) {
      final expiry = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiry)) {
        // Clean up expired token
        await repository.deleteToken(refreshToken);
        throw AuthException('Refresh token has expired');
      }
    }

    final userId = tokenRecord['tokenable_id'];

    // Get user information
    final provider = config.getProvider(providerKey);
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    final user = await repository.findUserById(userId, table, primaryKey);
    if (user == null) {
      throw AuthException('User not found');
    }

    // Generate new access token
    final newAccessToken = tokenGenerator.generateToken(
      prefix: userId.toString(),
    );

    // Generate new refresh token for security
    final newRefreshToken = tokenGenerator.generateRefreshToken();

    // Store the new access token
    final accessTokenData = {
      'token': newAccessToken,
      'tokenable_id': userId,
      'guard': providerKey,
      'type': 'access',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Add expiry if configured
    if (_tokenExpiry != null) {
      accessTokenData['expires_at'] =
          DateTime.now().add(_tokenExpiry!).toIso8601String();
    }

    await repository.storeToken(accessTokenData);

    // Store the new refresh token
    final refreshTokenData = {
      'token': newRefreshToken,
      'tokenable_id': userId,
      'guard': providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Refresh tokens typically have longer expiry
    final refreshExpiry = _tokenExpiry != null
        ? _tokenExpiry!.inHours > 24
            ? _tokenExpiry!
            : const Duration(days: 7) // Default 7 days for refresh tokens
        : const Duration(days: 7);

    refreshTokenData['expires_at'] =
        DateTime.now().add(refreshExpiry).toIso8601String();

    await repository.storeToken(refreshTokenData);

    // Invalidate the old refresh token for security
    await repository.deleteToken(refreshToken);

    return {
      'access_token': newAccessToken,
      'refresh_token': newRefreshToken,
      'token_type': 'Bearer',
      'expires_in': _tokenExpiry?.inSeconds,
      'refresh_expires_in': refreshExpiry.inSeconds,
    };
  }

  /// Cleanup expired tokens
  ///
  /// Returns the number of cleaned up tokens
  Future<int> cleanupExpiredTokens() async {
    return repository.cleanupExpiredTokens();
  }
}
