import '../contracts/auth_config.dart';
import '../contracts/auth_repository.dart';
import '../contracts/password_verifier.dart';
import '../contracts/token_generator.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';

/// Base authentication service implementing common functionality
///
/// This abstract class provides common authentication operations
/// and follows the Template Method pattern. Concrete implementations
/// should extend this class and implement the abstract methods.
abstract class BaseAuthService implements AuthDriver {
  /// Authentication repository for data access
  final AuthRepository repository;

  /// Authentication configuration
  final AuthConfig config;

  /// Password verification service
  final PasswordVerifier passwordVerifier;

  /// Token generation service
  final TokenGenerator tokenGenerator;

  /// The provider key for this service
  final String providerKey;

  /// Creates a base authentication service
  ///
  /// All dependencies are injected for better testability and flexibility
  BaseAuthService({
    required this.repository,
    required this.config,
    required this.passwordVerifier,
    required this.tokenGenerator,
    required this.providerKey,
  });

  @override
  Future<Map<String, dynamic>> attemptLogin(
    Map<String, dynamic> credentials,
  ) async {
    try {
      // Template method pattern - define the algorithm structure
      await validateCredentials(credentials);
      final provider = config.getProvider(providerKey);
      final user = await findUserByCredentials(credentials, provider);
      await verifyUserPassword(credentials, user);
      final authResult = await generateAuthResult(user, provider);
      await storeAuthSession(authResult, user, provider);

      return authResult;
    } catch (e) {
      await handleLoginFailure(e, credentials);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      await validateToken(token);
      final provider = config.getProvider(providerKey);
      final user = await findUserByToken(token, provider);
      await validateUserStatus(user);

      return user;
    } catch (e) {
      await handleTokenVerificationFailure(e, token);
      rethrow;
    }
  }

  @override
  Future<void> logout(String token) async {
    try {
      await validateToken(token);
      await invalidateToken(token);
      await handleLogoutSuccess(token);
    } catch (e) {
      await handleLogoutFailure(e, token);
      rethrow;
    }
  }

  /// Validates the provided credentials
  ///
  /// [credentials] The credentials to validate
  /// Override for custom validation logic
  Future<void> validateCredentials(Map<String, dynamic> credentials) async {
    if (credentials.isEmpty) {
      throw AuthException('No credentials provided');
    }

    final password = credentials['password'] as String?;
    if (password == null || password.isEmpty) {
      throw AuthException('Password is required');
    }
  }

  /// Finds a user by their credentials
  ///
  /// [credentials] User login credentials
  /// [provider] Authentication provider configuration
  /// Returns the user record
  Future<Map<String, dynamic>> findUserByCredentials(
    Map<String, dynamic> credentials,
    Map<String, dynamic> provider,
  ) async {
    final table = provider['table'] as String;
    final fields = List<String>.from(provider['fields'] as List);

    final user =
        await repository.findUserByCredentials(credentials, fields, table);

    if (user == null) {
      throw AuthException('Invalid credentials');
    }

    return user;
  }

  /// Verifies the user's password
  ///
  /// [credentials] User credentials
  /// [user] User record from database
  Future<void> verifyUserPassword(
    Map<String, dynamic> credentials,
    Map<String, dynamic> user,
  ) async {
    final password = credentials['password'] as String;
    final hashedPassword = user['password'] as String?;

    if (hashedPassword == null) {
      throw AuthException('User password not found');
    }

    final isValid = await passwordVerifier.verify(password, hashedPassword);
    if (!isValid) {
      throw AuthException('Invalid credentials');
    }
  }

  /// Validates token format and basic structure
  ///
  /// [token] The token to validate
  Future<void> validateToken(String token) async {
    if (token.isEmpty) {
      throw AuthException('Token is required');
    }

    if (!tokenGenerator.isValidTokenFormat(token)) {
      throw AuthException('Invalid token format');
    }
  }

  /// Validates user status (active, verified, etc.)
  ///
  /// [user] The user record to validate
  /// Override for custom user status validation
  Future<void> validateUserStatus(Map<String, dynamic> user) async {
    // Default implementation - can be overridden
    final isActive = user['is_active'] == true ||
        user['is_active'] == 1 ||
        user['is_active'] == '1' ||
        user['is_active'] == null;
    if (!isActive) {
      throw AuthException('User account is deactivated');
    }
  }

  /// Handles login failure events
  ///
  /// [error] The error that occurred
  /// [credentials] The credentials that were attempted
  /// Override for custom failure handling (logging, rate limiting, etc.)
  Future<void> handleLoginFailure(
    dynamic error,
    Map<String, dynamic> credentials,
  ) async {
    // Default implementation - can be overridden for logging, etc.
  }

  /// Handles token verification failure events
  ///
  /// [error] The error that occurred
  /// [token] The token that failed verification
  Future<void> handleTokenVerificationFailure(
    dynamic error,
    String token,
  ) async {
    // Default implementation - can be overridden for logging, etc.
  }

  /// Handles successful logout events
  ///
  /// [token] The token that was logged out
  Future<void> handleLogoutSuccess(String token) async {
    // Default implementation - can be overridden for logging, etc.
  }

  /// Handles logout failure events
  ///
  /// [error] The error that occurred
  /// [token] The token that failed to logout
  Future<void> handleLogoutFailure(dynamic error, String token) async {
    // Default implementation - can be overridden for logging, etc.
  }

  // Abstract methods that must be implemented by concrete classes

  /// Generates authentication result (tokens, user data, etc.)
  ///
  /// [user] The authenticated user
  /// [provider] Provider configuration
  /// Returns the authentication result
  Future<Map<String, dynamic>> generateAuthResult(
    Map<String, dynamic> user,
    Map<String, dynamic> provider,
  );

  /// Stores authentication session data
  ///
  /// [authResult] The authentication result
  /// [user] The user record
  /// [provider] Provider configuration
  Future<void> storeAuthSession(
    Map<String, dynamic> authResult,
    Map<String, dynamic> user,
    Map<String, dynamic> provider,
  );

  /// Finds a user by their authentication token
  ///
  /// [token] The authentication token
  /// [provider] Provider configuration
  /// Returns the user record
  Future<Map<String, dynamic>> findUserByToken(
    String token,
    Map<String, dynamic> provider,
  );

  /// Invalidates an authentication token
  ///
  /// [token] The token to invalidate
  Future<void> invalidateToken(String token);

  /// Refreshes an access token using a refresh token
  ///
  /// [refreshToken] The refresh token to use for generating a new access token
  /// Returns a new access token data
  /// Throws [AuthException] if refresh token is invalid or expired
  @override
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken);
}
