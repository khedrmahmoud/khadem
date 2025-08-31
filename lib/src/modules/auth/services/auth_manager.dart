import '../../../application/khadem.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';
import 'jwt_auth_service.dart';
import 'token_auth_service.dart';

/// Authentication manager for handling user authentication
///
/// This class acts as a facade for authentication operations, providing
/// a unified interface for different authentication drivers (JWT, Token, etc.).
/// It reads configuration to determine which authentication method to use
/// and delegates operations to the appropriate driver.
///
/// Features:
/// - Multi-driver support (JWT, Token, etc.)
/// - Configuration-driven driver selection
/// - Unified authentication interface
/// - Guard-based authentication contexts
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
  /// The authentication guard name
  late final String _guard;

  /// The authentication driver instance
  late final AuthDriver _driver;

  /// Creates an authentication manager instance
  ///
  /// [guard] The authentication guard to use (defaults to config default)
  /// Throws [AuthException] if auth configuration is missing or invalid
  AuthManager({String? guard}) {
    _initializeAuthManager(guard);
  }

  /// Initializes the authentication manager with configuration
  ///
  /// [guard] Optional guard name to override the default
  void _initializeAuthManager(String? guard) {
    try {
      final config = Khadem.config.section('auth');
      if (config == null) {
        throw AuthException('Authentication configuration not found. Please check your config/auth.php file.');
      }

      _guard = guard ?? config['default'] as String? ?? 'web';

      final guardConfig = config['guards']?[_guard];
      if (guardConfig == null) {
        throw AuthException('Authentication guard "$_guard" not found in configuration.');
      }

      final driverName = guardConfig['driver'] as String?;
      if (driverName == null) {
        throw AuthException('No driver specified for guard "$_guard".');
      }

      final providerKey = guardConfig['provider'] as String?;
      if (providerKey == null) {
        throw AuthException('No provider specified for guard "$_guard".');
      }

      // Initialize the appropriate driver
      _driver = _createDriver(driverName, providerKey);

    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Failed to initialize authentication manager: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Creates the appropriate authentication driver
  ///
  /// [driverName] The name of the driver to create
  /// [providerKey] The provider key for the driver
  /// Returns the configured authentication driver
  /// Throws [AuthException] for unsupported drivers
  AuthDriver _createDriver(String driverName, String providerKey) {
    switch (driverName.toLowerCase()) {
      case 'jwt':
        return JWTAuthService(providerKey: providerKey);
      case 'token':
        return TokenAuthService(providerKey: providerKey);
      default:
        throw AuthException('Unsupported authentication driver: $driverName');
    }
  }

  /// Attempts to authenticate a user with the provided credentials
  ///
  /// [credentials] A map containing authentication credentials
  /// Returns authentication result with user data and tokens
  /// Throws [AuthException] if authentication fails
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) =>
      _driver.attemptLogin(credentials);

  /// Verifies the validity of an authentication token
  ///
  /// [token] The authentication token to verify
  /// Returns the user data associated with the token
  /// Throws [AuthException] if token is invalid
  Future<Map<String, dynamic>> verify(String token) =>
      _driver.verifyToken(token);

  /// Logs out a user by invalidating their authentication token
  ///
  /// [token] The authentication token to invalidate
  /// Throws [AuthException] if logout fails
  Future<void> logout(String token) =>
      _driver.logout(token);

  /// Gets the current authentication guard name
  String get guard => _guard;

  /// Gets the current authentication driver
  AuthDriver get driver => _driver;
}
