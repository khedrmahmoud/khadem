import '../contracts/auth_config.dart';
import '../contracts/auth_repository.dart';
import '../contracts/authenticatable.dart';
import '../contracts/password_verifier.dart';
import '../core/auth_response.dart';
import '../core/database_authenticatable.dart';
import '../drivers/auth_driver.dart';
import '../exceptions/auth_exception.dart';
import '../repositories/database_auth_repository.dart';
import '../services/hash_password_verifier.dart';

/// Base authentication guard
///
/// Guards handle authentication for different contexts (web, api, etc.).
/// They use drivers to perform low-level token operations and repositories
/// for user data access.
abstract class Guard {
  /// Authentication configuration
  final AuthConfig config;

  /// Authentication repository
  final AuthRepository repository;

  /// Password verifier
  final PasswordVerifier passwordVerifier;

  /// The authentication driver
  final AuthDriver driver;

  /// The provider key
  final String providerKey;

  /// Creates a base guard
  Guard({
    required this.config,
    required this.driver, required this.providerKey, AuthRepository? repository,
    PasswordVerifier? passwordVerifier,
  })  : repository = repository ?? DatabaseAuthRepository(),
        passwordVerifier = passwordVerifier ?? HashPasswordVerifier();

  /// Attempts to authenticate a user with credentials
  ///
  /// [credentials] User login credentials
  /// Returns authentication response
  Future<AuthResponse> attempt(
    Map<String, dynamic> credentials,
  ) async {
    // Validate credentials
    await _validateCredentials(credentials);

    // Find user
    final user = await _findUserByCredentials(credentials);

    // Verify password
    await _verifyPassword(credentials, user);

    // Authenticate with driver
    return driver.authenticate(credentials, user);
  }

  /// Authenticates a user directly (without password check)
  ///
  /// [user] The user to authenticate
  /// Returns authentication response
  Future<AuthResponse> login(Authenticatable user) async {
    return driver.generateTokens(user);
  }

  /// Verifies an authentication token
  ///
  /// [token] The token to verify
  /// Returns the authenticated user
  Future<Authenticatable> user(String token) async {
    return driver.verifyToken(token);
  }

  /// Checks if a token is valid
  ///
  /// [token] The token to check
  /// Returns true if token is valid
  Future<bool> check(String token) async {
    try {
      await driver.verifyToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logs out a user by invalidating their token
  ///
  /// [token] The token to invalidate
  Future<void> logout(String token) async {
    await driver.invalidateToken(token);
  }

  /// Logs out the user from all devices (invalidates all tokens)
  ///
  /// [token] The user ID to logout from all devices
  Future<void> logoutAll(dynamic token) async {
    // Get all tokens for this user and guard
    return driver.logoutFromAllDevices(token);
  }

  /// Logs out the user from other devices (invalidates all tokens except current)
  ///
  /// [userId] The user ID
  /// [currentToken] The current token to keep active
  Future<void> logoutOthers(dynamic userId, String currentToken) async {
    // Get all tokens for this user and guard
    final tokens = await repository.findTokensByUser(userId, providerKey);

    // Delete all tokens except the current one
    for (final tokenData in tokens) {
      final token = tokenData['token'] as String;
      if (token != currentToken) {
        await repository.deleteToken(token);
      }
    }
  }

  /// Refreshes an access token
  ///
  /// [refreshToken] The refresh token
  /// Returns new authentication response
  Future<AuthResponse> refresh(String refreshToken) async {
    return driver.refreshToken(refreshToken);
  }

  /// Validates credentials format
  Future<void> _validateCredentials(Map<String, dynamic> credentials) async {
    if (credentials.isEmpty) {
      throw AuthException('No credentials provided');
    }

    final password = credentials['password'] as String?;
    if (password == null || password.isEmpty) {
      throw AuthException('Password is required');
    }
  }

  /// Finds a user by credentials
  Future<Authenticatable> _findUserByCredentials(
    Map<String, dynamic> credentials,
  ) async {
    final provider = config.getProvider(providerKey);
    final table = provider['table'] as String;
    final fields = List<String>.from(provider['fields'] as List);

    final userData = await repository.findUserByCredentials(
      credentials,
      fields,
      table,
    );

    if (userData == null) {
      // SECURITY: Use same error message to prevent username enumeration
      throw AuthException('Invalid credentials');
    }

    return _createAuthenticatable(userData);
  }

  /// Verifies user password
  Future<void> _verifyPassword(
    Map<String, dynamic> credentials,
    Authenticatable user,
  ) async {
    final password = credentials['password'] as String;
    final hashedPassword = user.getAuthPassword();

    if (hashedPassword == null) {
      // SECURITY: Use same error message to prevent information leakage
      throw AuthException('Invalid credentials');
    }

    final isValid = await passwordVerifier.verify(password, hashedPassword);
    if (!isValid) {
      // SECURITY: Use same error message to prevent information leakage
      throw AuthException('Invalid credentials');
    }
  }

  /// Creates an authenticatable instance from user data
  Authenticatable _createAuthenticatable(Map<String, dynamic> userData) {
    final provider = config.getProvider(providerKey);
    return DatabaseAuthenticatable.fromProviderConfig(userData, provider);
  }
}

