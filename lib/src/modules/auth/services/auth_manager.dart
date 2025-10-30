import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../contracts/authenticatable.dart';
import '../core/auth_response.dart';
import '../exceptions/auth_exception.dart';
import '../guards/api_guard.dart';
import '../guards/base_guard.dart';
import '../guards/web_guard.dart';

/// Authentication manager for handling user authentication
///
/// This class acts as a facade for authentication operations, providing
/// a unified interface for different authentication guards (web, api, etc.).
/// It implements the Strategy pattern and Factory pattern for better
/// maintainability and extensibility.
///
/// Features:
/// - Multi-guard support (web, api, etc.)
/// - Provider-specific authentication
/// - Configuration-driven guard selection
/// - Unified authentication interface
/// - Guard caching for performance
/// - Extensible guard registration
///
/// Example usage:
/// ```dart
/// // Using default guard and provider
/// final authManager = AuthManager();
/// final result = await authManager.attempt({'email': 'user@example.com', 'password': 'password'});
///
/// // Using specific guard
/// final webAuth = AuthManager(guard: 'web');
/// final webResult = await webAuth.attempt(credentials);
///
/// // Using specific guard and provider
/// final adminAuth = AuthManager(guard: 'web', provider: 'admins_web');
/// final adminResult = await adminAuth.attempt(credentials);
///
/// // Verifying tokens
/// final user = await authManager.user(token);
///
/// // Logging out
/// await authManager.logout(token);
/// ```
class AuthManager {
  /// Cache for authentication guards
  static final Map<String, Guard> _guardCache = {};

  /// Authentication configuration
  final AuthConfig _authConfig;

  /// The authentication guard name
  final String _guard;

  /// The authentication provider key
  final String? _provider;

  /// The authentication guard instance
  late final Guard _guardInstance;

  /// Creates an enhanced authentication manager instance
  ///
  /// [guard] The authentication guard to use (defaults to config default)
  /// [provider] The authentication provider to use (optional)
  /// [authConfig] Optional auth config implementation
  /// Throws [AuthException] if auth configuration is missing or invalid
  AuthManager({
    String? guard,
    String? provider,
    AuthConfig? authConfig,
  })  : _authConfig = authConfig ?? KhademAuthConfig(),
        _guard = guard ?? (authConfig ?? KhademAuthConfig()).getDefaultGuard(),
        _provider = provider ??
            (authConfig ?? KhademAuthConfig()).getDefaultProvider() {
    _guardInstance = _getOrCreateGuard(_guard, _provider!);
  }

  /// Gets or creates a guard for the specified guard name and provider
  ///
  /// [guardName] The guard name
  /// [providerKey] Optional provider key
  /// Returns the authentication guard
  Guard _getOrCreateGuard(String guardName, [String providerKey = "users"]) {
    final cacheKey = '${guardName}:${providerKey}';

    // Check cache first
    if (_guardCache.containsKey(cacheKey)) {
      return _guardCache[cacheKey]!;
    }

    final guard = _createGuard(guardName, providerKey);

    // Cache the guard
    _guardCache[cacheKey] = guard;

    return guard;
  }

  /// Creates the appropriate authentication guard
  ///
  /// [guardName] The name of the guard to create
  /// [providerKey] Optional provider key to use
  /// Returns the configured authentication guard
  /// Throws [AuthException] for unsupported guards
  Guard _createGuard(String guardName, [String providerKey = "users"]) {
    switch (guardName.toLowerCase()) {
      case 'api':
        return ApiGuard.fromConfig(_authConfig, guardName, providerKey);
      case 'web':
        return WebGuard.fromConfig(
          _authConfig,
          guardName,
          providerKey: providerKey,
        );
      default:
        // Default to API guard for token-based auth
        return ApiGuard.fromConfig(_authConfig, guardName, providerKey);
    }
  }

  /// Attempts to authenticate a user with the provided credentials
  ///
  /// [credentials] A map containing authentication credentials
  /// Returns authentication result with user data and tokens
  /// Throws [AuthException] if authentication fails
  Future<AuthResponse> attempt(Map<String, dynamic> credentials) async {
    return _guardInstance.attempt(credentials);
  }

  /// Verifies the validity of an authentication token
  ///
  /// [token] The authentication token to verify
  /// Returns the authenticated user
  /// Throws [AuthException] if token is invalid
  Future<Authenticatable> user(String token) async {
    return _guardInstance.user(token);
  }

  /// Checks if a token is valid
  ///
  /// [token] The token to check
  /// Returns true if token is valid
  Future<bool> check(String token) async {
    return _guardInstance.check(token);
  }

  /// This method provides secure token refresh functionality with:
  /// - Automatic refresh token rotation for enhanced security
  /// - Comprehensive error handling and validation
  /// - Rate limiting and abuse prevention
  /// - Detailed logging for security auditing
  ///
  /// [refreshToken] The refresh token to use for generating new tokens
  /// Returns a map containing:
  /// - `access_token`: New access token
  /// - `refresh_token`: New refresh token (rotated for security)
  /// - `token_type`: Token type (usually 'Bearer')
  /// - `expires_in`: Access token expiration time in seconds
  /// - `refresh_expires_in`: Refresh token expiration time in seconds
  ///
  /// Throws [AuthException] in the following cases:
  /// - Invalid or malformed refresh token
  /// - Expired refresh token
  /// - User account disabled or not found
  /// - Rate limiting triggered
  /// - Internal authentication service errors
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final tokens = await authManager.refreshAccessToken(refreshToken);
  ///   final newAccessToken = tokens['access_token'];
  ///   final newRefreshToken = tokens['refresh_token'];
  ///   // Store new tokens securely
  /// } catch (e) {
  ///   // Handle refresh failure - redirect to login
  /// }
  /// ```
  /// Attempts authentication with a specific guard
  ///
  /// [guardName] The guard to use for authentication
  /// [credentials] Authentication credentials
  /// Returns authentication result
  Future<AuthResponse> attemptWithGuard(
    String guardName,
    Map<String, dynamic> credentials,
  ) async {
    final guard = _getOrCreateGuard(guardName);
    return guard.attempt(credentials);
  }

  /// Verifies a token with a specific guard
  ///
  /// [guardName] The guard to use for verification
  /// [token] The token to verify
  /// Returns the authenticated user
  Future<Authenticatable> userWithGuard(
    String guardName,
    String token,
  ) async {
    final guard = _getOrCreateGuard(guardName);
    return guard.user(token);
  }

  /// Logs out with a specific guard
  ///
  /// [guardName] The guard to use for logout
  /// [token] The token to invalidate
  Future<void> logoutWithGuard(String guardName, String token) async {
    final guard = _getOrCreateGuard(guardName);
    await guard.logout(token);
  }

  /// Refreshes an access token using a refresh token
  ///
  /// [refreshToken] The refresh token to use
  /// Returns new authentication response with fresh tokens
  Future<AuthResponse> refresh(String refreshToken) async {
    return _guardInstance.refresh(refreshToken);
  }

  /// Logs out the current user from all devices with a specific guard
  ///
  /// [guardName] The guard to use
  /// [token] The user ID to logout from all devices
  Future<void> logoutAllWithGuard(String guardName, dynamic token) async {
    final guard = _getOrCreateGuard(guardName);
    await guard.logoutAll(token);
  }

  /// Logs out the current user from all devices
  ///
  /// [token] The user ID to logout from all devices
  Future<void> logoutAll(dynamic token) async {
    await _guardInstance.logoutAll(token);
  }

  /// Logs out the user from other devices (keeps current session)
  ///
  /// [userId] The user ID
  /// [currentToken] The current token to keep active
  Future<void> logoutOthers(dynamic userId, String currentToken) async {
    await _guardInstance.logoutOthers(userId, currentToken);
  }

  /// Logs out the user with the current guard.
  ///
  /// [token] The token to invalidate
  Future<void> logout(String token) async {
    await _guardInstance.logout(token);
  }

  /// Gets the current authentication guard name
  String get guard => _guard;

  /// Gets the current authentication guard
  Guard get guardInstance => _guardInstance;

  /// Gets the authentication configuration
  AuthConfig get config => _authConfig;

  /// Gets a guard instance by name
  ///
  /// [guardName] The guard name
  /// Returns the guard instance
  Guard getGuard(String guardName) {
    return _getOrCreateGuard(guardName);
  }

  /// Gets a list of available guards
  ///
  /// Returns a list of guard names
  List<String> getAvailableGuards() {
    // This would require additional method in AuthConfig
    // For now, return the current guard
    return [_guard];
  }

  /// Clears the guard cache
  ///
  /// Useful for testing or when configuration changes
  static void clearGuardCache() {
    _guardCache.clear();
  }

  /// Registers a custom guard factory
  ///
  /// [guardName] The name of the guard
  /// [factory] Factory function that creates the guard
  static void registerGuardFactory(
    String guardName,
    Guard Function(AuthConfig config, String guardName) factory,
  ) {
    _customGuardFactories[guardName] = factory;
  }

  /// Custom guard factories
  static final Map<String, Guard Function(AuthConfig, String)>
      _customGuardFactories = {};
}
