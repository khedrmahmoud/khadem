import '../../../contracts/session/session_interfaces.dart';
import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../contracts/authenticatable.dart';
import '../core/auth_response.dart';
import '../core/database_authenticatable.dart';
import '../drivers/auth_driver.dart';
import '../drivers/jwt_driver.dart';
import '../drivers/token_driver.dart';
import '../exceptions/auth_exception.dart';
import '../repositories/database_auth_repository.dart';
import '../services/hash_password_verifier.dart';
import 'base_guard.dart';

/// Web authentication guard
///
/// This guard handles authentication for web applications. It supports
/// session-based authentication and can work with various drivers.
/// It's designed for stateful web applications where sessions are maintained.
class WebGuard extends Guard {
  /// Session manager for handling session operations
  final ISessionManager? _sessionManager;

  /// Session key for storing user ID
  static const String _sessionUserKey = 'auth_user_id';

  /// Session key for storing remember me token
  static const String _sessionRememberKey = 'auth_remember_token';

  /// Creates a web guard
  WebGuard({
    required super.config,
    required super.driver,
    required super.providerKey,
    super.repository,
    super.passwordVerifier,
    ISessionManager? sessionManager,
  }) : _sessionManager = sessionManager;

  /// Factory constructor for easy instantiation
  factory WebGuard.create(
    String providerKey,
    AuthDriver driver, {
    ISessionManager? sessionManager,
  }) {
    return WebGuard(
      config: KhademAuthConfig(),
      repository: DatabaseAuthRepository(),
      passwordVerifier: HashPasswordVerifier(),
      driver: driver,
      providerKey: providerKey,
      sessionManager: sessionManager,
    );
  }

  /// Factory constructor with config
  factory WebGuard.fromConfig(
    AuthConfig config,
    String guardName, {
    ISessionManager? sessionManager,
    String? providerKey,
  }) {
    final guardConfig = config.getGuard(guardName);
    final driverName = guardConfig['driver'] as String;

    // Use provided provider key, or get default provider
    final effectiveProviderKey = providerKey ?? _getDefaultProviderKey(config);

    final driver = _createDriver(driverName, config, effectiveProviderKey);

    return WebGuard(
      config: config,
      driver: driver,
      providerKey: effectiveProviderKey,
      sessionManager: sessionManager,
    );
  }

  /// Gets the default provider key
  static String _getDefaultProviderKey(AuthConfig config) {
    final providerKeys = config.getAllProviderKeys();
    if (providerKeys.isEmpty) {
      throw AuthException('No providers configured');
    }

    // Return the first provider key as default
    return providerKeys.first;
  }

  /// Creates the appropriate driver
  static AuthDriver _createDriver(
    String driverName,
    AuthConfig config,
    String providerKey,
  ) {
    switch (driverName.toLowerCase()) {
      case 'jwt':
        return JWTDriver.fromConfig(config, providerKey);
      case 'token':
        return TokenDriver.fromConfig(config, providerKey);
      default:
        throw AuthException('Unsupported driver: $driverName');
    }
  }

  /// Authenticates via session (web-specific)
  ///
  /// In web applications, this authenticates credentials but does not
  /// automatically store in session. Use loginWithSessionId for that.
  @override
  Future<AuthResponse> attempt(Map<String, dynamic> credentials) async {
    // Use parent authentication logic
    return super.attempt(credentials);
  }

  /// Gets the authenticated user from session
  ///
  /// [token] In web context, this is the session ID
  @override
  Future<Authenticatable> user(String sessionId) async {
    if (_sessionManager == null) {
      throw AuthException(
        'Session manager not available for web authentication',
      );
    }

    // Try to get user ID from session
    final userId = await _getUserIdFromSession(sessionId);
    if (userId == null) {
      throw AuthException('User not authenticated');
    }

    // Get user from database
    final provider = config.getProvider(providerKey);
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    final userData = await repository.findUserById(userId, table, primaryKey);
    if (userData == null) {
      throw AuthException('User not found');
    }

    return _createAuthenticatable(userData);
  }

  /// Checks if user is authenticated via session
  ///
  /// [token] In web context, this is the session ID
  @override
  Future<bool> check(String sessionId) async {
    if (_sessionManager == null) {
      return false;
    }

    try {
      final userId = await _getUserIdFromSession(sessionId);
      return userId != null;
    } catch (e) {
      return false;
    }
  }

  /// Logs out user by clearing session
  ///
  /// [token] In web context, this is the session ID
  @override
  Future<void> logout(String sessionId) async {
    if (_sessionManager != null) {
      await _clearUserFromSession(sessionId);
    }
  }

  /// Logs in user and stores in specific session
  ///
  /// [user] The user to log in
  /// [sessionId] The session ID to store user in
  /// Returns authentication response
  Future<AuthResponse> loginWithSessionId(
    Authenticatable user,
    String sessionId,
  ) async {
    // Generate tokens using driver
    final authResponse = await driver.generateTokens(user);

    // Store user ID in session
    if (_sessionManager != null) {
      await _storeUserInSessionById(sessionId, user.getAuthIdentifier());
    }

    return authResponse;
  }

  /// Logs in user with remember me and stores in specific session
  ///
  /// [user] The user to log in
  /// [sessionId] The session ID to store user in
  /// [remember] Whether to remember the user
  /// Returns authentication response
  Future<AuthResponse> loginWithSessionIdAndRemember(
    Authenticatable user,
    String sessionId, {
    bool remember = false,
  }) async {
    final authResponse = await loginWithSessionId(user, sessionId);

    if (remember && _sessionManager != null) {
      final rememberToken = await _generateRememberToken(user);
      await _storeRememberTokenInSessionById(sessionId, rememberToken);
    }

    return authResponse;
  }

  /// Logs out user from specific session
  ///
  /// [sessionId] The session ID to clear user from
  Future<void> logoutWithSessionId(String sessionId) async {
    if (_sessionManager != null) {
      await _clearUserFromSession(sessionId);
    }
  }

  /// Gets user ID from session
  Future<dynamic> _getUserIdFromSession(String sessionId) async {
    if (_sessionManager == null) return null;

    final sessionData = await _sessionManager!.getSession(sessionId);
    if (sessionData == null) return null;

    final data = sessionData['data'] as Map<String, dynamic>?;
    return data?[_sessionUserKey];
  }

  /// Stores user ID in specific session
  Future<void> _storeUserInSessionById(String sessionId, dynamic userId) async {
    if (_sessionManager == null) return;

    await _sessionManager!.setSessionValue(sessionId, _sessionUserKey, userId);
  }

  /// Stores remember token in specific session
  Future<void> _storeRememberTokenInSessionById(
    String sessionId,
    String token,
  ) async {
    if (_sessionManager == null) return;

    await _sessionManager!
        .setSessionValue(sessionId, _sessionRememberKey, token);
  }

  /// Clears user from session
  Future<void> _clearUserFromSession(String sessionId) async {
    if (_sessionManager == null) return;

    await _sessionManager!.removeSessionValue(sessionId, _sessionUserKey);
    await _sessionManager!.removeSessionValue(sessionId, _sessionRememberKey);
  }

  /// Generates remember me token
  Future<String> _generateRememberToken(Authenticatable user) async {
    // Generate a secure remember token
    final token = await driver.generateTokens(user);
    return token.accessToken ?? ''; // Use access token as remember token
  }

  /// Creates an authenticatable instance from user data
  Authenticatable _createAuthenticatable(Map<String, dynamic> userData) {
    final provider = config.getProvider(providerKey);
    return DatabaseAuthenticatable.fromProviderConfig(userData, provider);
  }
}
