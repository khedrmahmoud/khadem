import '../contracts/auth_config.dart';
import '../contracts/auth_repository.dart';
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

/// Token-based authentication driver
///
/// This driver handles simple token authentication with database storage.
/// It generates secure random tokens and stores them in the database
/// with optional expiry times.
///
/// Follows SOLID principles with dependency injection and strategy pattern.
class TokenDriver implements AuthDriver {
  /// Authentication repository (legacy - being phased out)
  final AuthRepository _repository;

  /// Token service for database operations
  final TokenService _tokenService;

  /// Token generator
  final TokenGenerator _tokenGenerator;

  /// Strategy factory for token invalidation
  final TokenInvalidationStrategyFactory _strategyFactory;

  /// Token expiry duration
  final Duration? _tokenExpiry;

  /// Provider key
  final String _providerKey;

  /// Auth config
  final AuthConfig _config;

  /// Creates a token driver with dependency injection
  TokenDriver({
    required String providerKey,
    required AuthConfig config,
    AuthRepository? repository,
    TokenService? tokenService,
    TokenGenerator? tokenGenerator,
    TokenInvalidationStrategyFactory? strategyFactory,
    Duration? tokenExpiry,
  })  : _repository = repository ?? DatabaseAuthRepository(),
        _tokenService = tokenService ?? DatabaseTokenService(),
        _tokenGenerator = tokenGenerator ?? SecureTokenGenerator(),
        _strategyFactory = strategyFactory ??
            TokenInvalidationStrategyFactory(
              tokenService ?? DatabaseTokenService(),
            ),
        _tokenExpiry = tokenExpiry,
        _providerKey = providerKey,
        _config = config;

  /// Factory constructor with config and dependency injection
  factory TokenDriver.fromConfig(
    AuthConfig config,
    String providerKey, {
    AuthRepository? repository,
    TokenService? tokenService,
    TokenGenerator? tokenGenerator,
    TokenInvalidationStrategyFactory? strategyFactory,
  }) {
    final provider = config.getProvider(providerKey);

    final tokenExpiry = provider['token_expiry'] != null
        ? Duration(seconds: provider['token_expiry'] as int)
        : null;

    final tokenServiceInstance = tokenService ?? DatabaseTokenService();

    return TokenDriver(
      repository: repository,
      tokenService: tokenServiceInstance,
      tokenGenerator: tokenGenerator,
      strategyFactory: strategyFactory ??
          TokenInvalidationStrategyFactory(tokenServiceInstance),
      providerKey: providerKey,
      tokenExpiry: tokenExpiry,
      config: config,
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
    final tokenRecord = await _tokenService.findToken(token);

    if (tokenRecord == null) {
      throw AuthException('Invalid token');
    }

    // Check token expiry
    final expiresAt = tokenRecord['expires_at'] as String?;
    if (expiresAt != null) {
      final expiry = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiry)) {
        await _tokenService.deleteToken(token);
        throw AuthException('Token has expired');
      }
    }

    // Get user data
    final provider = await _getProviderConfig();
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;
    final userId = tokenRecord['tokenable_id'];

    final userData = await _repository.findUserById(userId, table, primaryKey);

    if (userData == null) {
      throw AuthException('User not found');
    }

    return DatabaseAuthenticatable.fromProviderConfig(
      userData,
      provider,
    );
  }

  @override
  Future<AuthResponse> generateTokens(Authenticatable user) async {
    final userId = user.getAuthIdentifier();
    final accessToken = _tokenGenerator.generateToken(
      prefix: userId.toString(),
    );

    // Store access token in database using injected service
    final tokenData = {
      'token': accessToken,
      'tokenable_id': userId,
      'guard': _providerKey,
      'type': 'access',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_tokenExpiry != null) {
      tokenData['expires_at'] =
          DateTime.now().add(_tokenExpiry!).toIso8601String();
    }

    await _tokenService.storeToken(tokenData);

    // For Token driver, we can optionally generate refresh tokens too
    // This provides consistency with JWT driver behavior
    final refreshToken = _tokenGenerator.generateToken();

    // Store refresh token
    final refreshTokenData = {
      'token': refreshToken,
      'tokenable_id': userId,
      'guard': _providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };

    await _tokenService.storeToken(refreshTokenData);

    return AuthResponse(
      user: user.toAuthArray(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: _tokenExpiry?.inSeconds,
      refreshExpiresIn: 604800, // 7 days
    );
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
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

    // Get user
    final provider = await _getProviderConfig();
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    final userData = await _repository.findUserById(userId, table, primaryKey);
    if (userData == null) {
      throw AuthException('User not found');
    }

    final user = DatabaseAuthenticatable.fromProviderConfig(
      userData,
      provider,
    );

    // Generate new tokens
    final newAccessToken = _tokenGenerator.generateToken(
      prefix: userId.toString(),
    );

    final newRefreshToken = _tokenGenerator.generateToken();

    // Store new access token
    final accessTokenData = {
      'token': newAccessToken,
      'tokenable_id': userId,
      'guard': _providerKey,
      'type': 'access',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_tokenExpiry != null) {
      accessTokenData['expires_at'] =
          DateTime.now().add(_tokenExpiry!).toIso8601String();
    }

    await _tokenService.storeToken(accessTokenData);

    // Store new refresh token
    final refreshTokenData = {
      'token': newRefreshToken,
      'tokenable_id': userId,
      'guard': _providerKey,
      'type': 'refresh',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };

    await _tokenService.storeToken(refreshTokenData);

    // Clean up old refresh token
    await _tokenService.deleteToken(refreshToken);

    return AuthResponse(
      user: user.toAuthArray(),
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: _tokenExpiry?.inSeconds,
      refreshExpiresIn: 604800, // 7 days
    );
  }

  @override
  Future<void> invalidateToken(String token) async {
    // Use single device logout strategy by default for stateful tokens
    final strategy = _strategyFactory.createStrategy(LogoutType.singleDevice);

    // Get token info to create context
    final tokenRecord = await _tokenService.findToken(token);
    if (tokenRecord == null) {
      throw AuthException('Invalid token');
    }

    final userId = tokenRecord['tokenable_id'];

    // For Token driver, we don't have JWT expiry, so we pass null
    // This tells the strategy to handle it as a stateful token
    final context = TokenInvalidationContext.fromTokens(
      accessToken: token,
      userId: userId,
      guard: _providerKey,
      // No tokenExpiry for stateful tokens - this signals the strategy
      // to use delete instead of blacklist
    );

    await strategy.invalidateTokens(context);
  }

  /// Invalidates tokens using a specific strategy
  ///
  /// [token] The access token
  /// [logoutType] The type of logout strategy to use
  @override
  Future<void> invalidateTokenWithStrategy(
    String token,
    LogoutType logoutType,
  ) async {
    final strategy = _strategyFactory.createStrategy(logoutType);

    // Get token info to create context
    final tokenRecord = await _tokenService.findToken(token);
    if (tokenRecord == null) {
      throw AuthException('Invalid token');
    }

    final userId = tokenRecord['tokenable_id'];

    final context = TokenInvalidationContext.fromTokens(
      accessToken: token,
      userId: userId,
      guard: _providerKey,
    );

    await strategy.invalidateTokens(context);
  }

  /// Logout from all devices
  @override
  Future<void> logoutFromAllDevices(String token) async {
    await invalidateTokenWithStrategy(token, LogoutType.allDevices);
  }

  @override
  bool validateTokenFormat(String token) {
    return token.isNotEmpty && token.length >= 32;
  }

  /// Gets the provider configuration
  Future<Map<String, dynamic>> _getProviderConfig() async {
    return _config.getProvider(_providerKey);
  }
}
