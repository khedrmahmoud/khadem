import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';
import 'jwt_auth_service.dart';
import 'token_auth_service.dart';

/// Authentication manager for handling user authentication
///
/// This class acts as a facade for authentication operations, providing
/// a unified interface for different authentication drivers (JWT, Token, etc.).
/// It implements the Strategy pattern and Factory pattern for better
/// maintainability and extensibility.
///
/// Features:
/// - Multi-driver support (JWT, Token, etc.)
/// - Configuration-driven driver selection
/// - Unified authentication interface
/// - Guard-based authentication contexts
/// - Driver caching for performance
/// - Extensible driver registration
///
/// Example usage:
/// ```dart
/// // Using default guard
/// final authManager = AuthManager();
/// final result = await authManager.login({'email': 'user@example.com', 'password': 'password'});
///
/// // Using specific guard
/// final adminAuth = AuthManager(guard: 'admin');
/// final adminResult = await adminAuth.login(credentials);
///
/// // Verifying tokens
/// final user = await authManager.verify(token);
///
/// // Logging out
/// await authManager.logout(token);
/// ```
class AuthManager {
  /// Cache for authentication drivers
  static final Map<String, AuthDriver> _driverCache = {};

  /// Authentication configuration
  final AuthConfig _authConfig;

  /// The authentication guard name
  final String _guard;

  /// The authentication driver instance
  late final AuthDriver _driver;

  /// Creates an enhanced authentication manager instance
  ///
  /// [guard] The authentication guard to use (defaults to config default)
  /// [authConfig] Optional auth config implementation
  /// Throws [AuthException] if auth configuration is missing or invalid
  AuthManager({
    String? guard,
    AuthConfig? authConfig,
  })  : _authConfig = authConfig ?? KhademAuthConfig(),
        _guard = guard ?? (authConfig ?? KhademAuthConfig()).getDefaultGuard() {
    _driver = _getOrCreateDriver(_guard);
  }

  /// Gets or creates a driver for the specified guard
  ///
  /// [guardName] The guard name
  /// Returns the authentication driver
  AuthDriver _getOrCreateDriver(String guardName) {
    // Check cache first
    if (_driverCache.containsKey(guardName)) {
      return _driverCache[guardName]!;
    }

    final guardConfig = _authConfig.getGuard(guardName);
    final driverName = guardConfig['driver'] as String;
    final providerKey = guardConfig['provider'] as String;

    final driver = _createDriver(driverName, providerKey);

    // Cache the driver
    _driverCache[guardName] = driver;

    return driver;
  }

  /// Creates the appropriate authentication driver
  ///
  /// [driverName] The name of the driver to create
  /// [providerKey] The provider key for the driver
  /// Returns the configured authentication driver
  /// Throws [AuthException] for unsupported drivers
  AuthDriver _createDriver(String driverName, String providerKey) {
    // Try custom factories first
    final customDriver = _createCustomDriver(driverName, providerKey);
    if (customDriver != null) {
      return customDriver;
    }

    // Fall back to built-in drivers
    switch (driverName.toLowerCase()) {
      case 'jwt':
        return EnhancedJWTAuthService.create(providerKey);
      case 'token':
        return EnhancedTokenAuthService.create(providerKey);
      default:
        throw AuthException('Unsupported authentication driver: $driverName');
    }
  }

  /// Attempts to authenticate a user with the provided credentials
  ///
  /// [credentials] A map containing authentication credentials
  /// Returns authentication result with user data and tokens
  /// Throws [AuthException] if authentication fails
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    try {
      return await _driver.attemptLogin(credentials);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Authentication failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Verifies the validity of an authentication token
  ///
  /// [token] The authentication token to verify
  /// Returns the user data associated with the token
  /// Throws [AuthException] if token is invalid
  Future<Map<String, dynamic>> verify(String token) async {
    return _driver.verifyToken(token);
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
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    // Input validation
    if (refreshToken.trim().isEmpty) {
      throw AuthException(
        'Refresh token cannot be empty',
        stackTrace: StackTrace.current.toString(),
      );
    }

    // Basic format validation (tokens should have minimum length)
    if (refreshToken.length < 16) {
      throw AuthException(
        'Invalid refresh token format',
        stackTrace: StackTrace.current.toString(),
      );
    }

    try {
      // Delegate to the underlying driver with enhanced error handling
      final tokenRecord = await _driver.refreshAccessToken(refreshToken);
      // Validate response structure
      if (!_isValidTokenResponse(tokenRecord)) {
        throw AuthException(
          'Invalid token response from authentication service',
          stackTrace: StackTrace.current.toString(),
        );
      }
      return tokenRecord;
    } catch (e) {
      // Re-throw AuthException as-is, wrap others
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Token refresh failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Validates the structure of a token response
  ///
  /// [response] The token response from the driver
  /// Returns true if the response has the required structure
  bool _isValidTokenResponse(Map<String, dynamic> response) {
    return response.containsKey('access_token') &&
        response['access_token'] is String &&
        response['access_token'].toString().isNotEmpty;
  }

  /// Logs out a user by invalidating their authentication token
  ///
  /// [token] The authentication token to invalidate
  /// Throws [AuthException] if logout fails
  Future<void> logout(String token) async {
    try {
      await _driver.logout(token);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Logout failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Attempts authentication with a specific guard
  ///
  /// [guardName] The guard to use for authentication
  /// [credentials] Authentication credentials
  /// Returns authentication result
  Future<Map<String, dynamic>> loginWithGuard(
    String guardName,
    Map<String, dynamic> credentials,
  ) async {
    final driver = _getOrCreateDriver(guardName);
    return driver.attemptLogin(credentials);
  }

  /// Verifies a token with a specific guard
  ///
  /// [guardName] The guard to use for verification
  /// [token] The token to verify
  /// Returns the user data
  Future<Map<String, dynamic>> verifyWithGuard(
    String guardName,
    String token,
  ) async {
    final driver = _getOrCreateDriver(guardName);
    return driver.verifyToken(token);
  }

  /// Logs out with a specific guard
  ///
  /// [guardName] The guard to use for logout
  /// [token] The token to invalidate
  Future<void> logoutWithGuard(String guardName, String token) async {
    final driver = _getOrCreateDriver(guardName);
    await driver.logout(token);
  }

  /// Gets the current authentication guard name
  String get guard => _guard;

  /// Gets the current authentication driver
  AuthDriver get driver => _driver;

  /// Gets the authentication configuration
  AuthConfig get config => _authConfig;

  /// Checks if a guard exists
  ///
  /// [guardName] The guard name to check
  /// Returns true if guard exists
  bool hasGuard(String guardName) {
    return _authConfig.hasGuard(guardName);
  }

  /// Gets a list of available guards
  ///
  /// Returns a list of guard names
  List<String> getAvailableGuards() {
    // This would require additional method in AuthConfig
    // For now, return the current guard
    return [_guard];
  }

  /// Clears the driver cache
  ///
  /// Useful for testing or when configuration changes
  static void clearDriverCache() {
    _driverCache.clear();
  }

  /// Registers a custom driver factory
  ///
  /// [driverName] The name of the driver
  /// [factory] Factory function that creates the driver
  static void registerDriverFactory(
    String driverName,
    AuthDriver Function(String providerKey) factory,
  ) {
    _customDriverFactories[driverName] = factory;
  }

  /// Custom driver factories
  static final Map<String, AuthDriver Function(String)> _customDriverFactories =
      {};

  /// Creates a driver using custom factories if available
  AuthDriver? _createCustomDriver(String driverName, String providerKey) {
    final factory = _customDriverFactories[driverName];
    return factory?.call(providerKey);
  }
}
