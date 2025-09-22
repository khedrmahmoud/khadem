import 'dart:convert';
import 'dart:math';

import 'package:khadem/khadem.dart';

/// Web Authentication Service
///
/// Handles session-based authentication for web applications,
/// Enhanced with powerful session management and security features.
class WebAuthService {
  static const String _sessionKey = 'user_id';
  static const String _rememberKey = 'remember_token';
  static const String _csrfKey = 'csrf_token';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _lockoutUntilKey = 'lockout_until';

  final AuthManager _authManager;
  final int _maxLoginAttempts = 5;
  final Duration _lockoutDuration = const Duration(minutes: 15);

  WebAuthService({String? guard}) : _authManager = AuthManager(guard: guard);

  /// Checks if the account is currently locked out due to failed attempts
  bool _isLockedOut(Request request) {
    final lockoutUntil = request.session.get(_lockoutUntilKey);
    if (lockoutUntil == null) return false;

    final lockoutTime = DateTime.tryParse(lockoutUntil.toString());
    if (lockoutTime == null) return false;

    return DateTime.now().isBefore(lockoutTime);
  }

  /// Records a failed login attempt
  void _recordFailedAttempt(Request request) {
    final attempts = request.session.get(_loginAttemptsKey) as int? ?? 0;
    final newAttempts = attempts + 1;

    request.session.set(_loginAttemptsKey, newAttempts);
    request.session.set(_lastLoginAttemptKey, DateTime.now().toIso8601String());

    // Lock account if max attempts reached
    if (newAttempts >= _maxLoginAttempts) {
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      request.session.set(_lockoutUntilKey, lockoutUntil.toIso8601String());
    }
  }

  /// Resets login attempts counter on successful login
  void _resetLoginAttempts(Request request) {
    request.removeSession(_loginAttemptsKey);
    request.removeSession(_lastLoginAttemptKey);
    request.removeSession(_lockoutUntilKey);
  }

  /// Attempts to authenticate a user for web session with enhanced security
  Future<Map<String, dynamic>> attemptLogin(
    Map<String, dynamic> credentials, {
    bool remember = false,
  }) async {
    final request = RequestContext.request;
    final response = ResponseContext.response;

    // Check for brute force protection
    if (_isLockedOut(request)) {
      throw AuthException(
        'Account temporarily locked due to too many failed attempts',
      );
    }

    try {
      // Authenticate user
      final authResult = await _authManager.login(credentials);

      // Reset login attempts on successful login
      _resetLoginAttempts(request);

      // Store user, tokens, and CSRF in session and cookies
      _saveAuthSession(request, response, authResult, remember);

      request.session.flash('message', 'Successfully logged in!');
      request.session.flash('message_type', 'success');

      // Return full auth result
      return authResult;
    } catch (e) {
      // Track failed login attempts
      _recordFailedAttempt(request);

      // Set error flash message
      request.session.flash('message', 'Invalid credentials');
      request.session.flash('message_type', 'error');

      throw AuthException('Web authentication failed: ${e.toString()}');
    }
  }

  void _saveAuthSession(
    Request request,
    Response response,
    Map<String, dynamic> authResult,
    bool remember,
  ) {
    // Extract user from auth result
    final user = Map<String, dynamic>.from(authResult['user']);
    final userId = user['id'];

    // Set user in request context
    request.setUser(user);

    // Store user ID in session (more secure than cookies)
    request.setSession(_sessionKey, userId.toString());

    // Generate and set CSRF token in session
    final csrfBytes = List<int>.generate(32, (_) => Random().nextInt(256));
    final csrfToken = base64Url.encode(csrfBytes);
    request.setSession(_csrfKey, csrfToken);
    // Also set in cookie for forms
    response.cookieHandler.set(_csrfKey, csrfToken);

    // Handle auth tokens (JWT vs simple token)
    final tokenData = authResult['token'];
    late String accessToken;
    String? refreshToken;
    if (tokenData is Map<String, dynamic>) {
      accessToken = tokenData['access_token'] as String;
      refreshToken = tokenData['refresh_token'] as String?;
    } else if (tokenData is String) {
      accessToken = tokenData;
    } else {
      throw AuthException('Unsupported token type for web authentication');
    }

    // Store tokens in session (secure)
    request.session.set('access_token', accessToken);
    if (refreshToken != null) {
      request.session.set('refresh_token', refreshToken);
    }

    // Set remember cookie if requested (long-lived cookie)
    if (remember) {
      final rememberToken = refreshToken ?? accessToken;
      response.cookieHandler.set(
        _rememberKey,
        rememberToken,
        maxAge: const Duration(days: 30),
        httpOnly: true,
        secure: true,
      );
    }

    // Set session timeout for security (30 minutes)
    request.session.setTimeout(const Duration(minutes: 30));

    // Store login timestamp
    request.session.set('login_time', DateTime.now().toIso8601String());
  }

  /// Logs out the current user from web session with thorough cleanup
  Future<void> logout(Request request, Response response) async {
    // Clear remember cookie if exists
    response.cookieHandler.delete(_rememberKey);

    // Clear session data
    request.session.remove(_sessionKey);
    request.session.remove(_csrfKey);
    request.session.remove('access_token');
    request.session.remove('refresh_token');
    request.session.remove('login_time');

    // Clear user context
    request.clearUser();

    // Regenerate session ID for security
    request.session.regenerateId();

    // Set logout flash message
    request.session.flash('message', 'Successfully logged out!');
    request.session.flash('message_type', 'success');

    // Optional: Clear all session data for complete logout
    // request.session.clear();
  }

  /// Checks if user is authenticated with enhanced validation
  bool isAuthenticated(Request request) {
    // Check session validity first
    if (!request.session.isValid()) {
      return false;
    }

    // Check if user ID exists in session
    final userId = request.session.get(_sessionKey);
    if (userId == null || userId.toString().isEmpty) {
      return false;
    }

    // Check if session is expired
    if (request.session.isExpired()) {
      return false;
    }

    return true;
  }

  /// Gets the current authenticated user with validation
  Future<Map<String, dynamic>?> getCurrentUser(Request request) async {
    if (!isAuthenticated(request)) {
      return null;
    }

    try {
      final accessToken = request.session.get('access_token') as String?;
      if (accessToken != null) {
        final userData = await _authManager.verify(accessToken);
        return userData;
      }
    } catch (e) {
      // Token invalid, clear session
      await logout(request, ResponseContext.response);
    }

    return null;
  }

  /// Validates CSRF token for security
  bool validateCsrfToken(Request request, String token) {
    final sessionToken = request.session.get(_csrfKey) as String?;
    return sessionToken != null && sessionToken == token;
  }

  /// Generates a new CSRF token
  String generateCsrfToken(Request request) {
    final csrfBytes = List<int>.generate(32, (_) => Random().nextInt(256));
    final csrfToken = base64Url.encode(csrfBytes);
    request.session.set(_csrfKey, csrfToken);
    return csrfToken;
  }

  /// Gets the current CSRF token
  String? getCsrfToken(Request request) {
    return request.session.get(_csrfKey) as String?;
  }

  /// Attempts to authenticate using remember token
  Future<Map<String, dynamic>?> attemptRememberLogin(Request request) async {
    final rememberToken = request.cookieHandler.get(_rememberKey);
    if (rememberToken == null) return null;

    try {
      final userData = await _authManager.verify(rememberToken);
      // Set user in session
      request.setUser(userData);
      request.session.set(_sessionKey, userData['id'].toString());
      return userData;
    } catch (e) {
      // Invalid remember token, clear it
      ResponseContext.response.cookieHandler.delete(_rememberKey);
      return null;
    }
  }

  /// Checks if user needs re-authentication (session expiring soon)
  bool needsReauth(
    Request request, {
    Duration within = const Duration(minutes: 5),
  }) {
    return request.session.isExpiringSoon(within);
  }

  /// Extends the current session
  void extendSession(Request request) {
    request.session.setTimeout(const Duration(minutes: 30));
  }

  /// Gets authentication status with details
  Map<String, dynamic> getAuthStatus(Request request) {
    final isAuth = isAuthenticated(request);
    final user = request.user;

    return {
      'is_authenticated': isAuth,
      'user': user,
      'session_expiring_soon': isAuth && request.session.isExpiringSoon(),
      'session_age': isAuth ? request.session.getAge().inMinutes : 0,
      'csrf_token': getCsrfToken(request),
      'login_time': isAuth ? request.session.get('login_time') : null,
    };
  }

  /// Middleware helper: Redirects unauthenticated users
  Future<void> requireAuth(
    Request request,
    Response response, {
    String redirectTo = '/login',
  }) async {
    if (!isAuthenticated(request)) {
      response.redirect(redirectTo);
      return;
    }

    // Check if session needs refresh
    if (request.session.shouldRegenerate()) {
      request.session.regenerateId();
    }
  }

  /// Middleware helper: Redirects authenticated users (for login pages)
  void redirectIfAuthenticated(
    Request request,
    Response response, {
    String redirectTo = '/dashboard',
  }) {
    if (isAuthenticated(request)) {
      response.redirect(redirectTo);
    }
  }

  /// Gets user data for views
  Map<String, dynamic> getViewData(Request request) {
    final authStatus = getAuthStatus(request);

    return {
      'auth': authStatus,
      'user': authStatus['user'],
      'is_authenticated': authStatus['is_authenticated'],
      'csrf_token': authStatus['csrf_token'],
      'flash_message': request.session.pull('message'),
      'flash_message_type': request.session.pull('message_type'),
    };
  }

  /// Sets flash message for next request
  void flashMessage(Request request, String message, {String type = 'info'}) {
    request.session.flash('message', message);
    request.session.flash('message_type', type);
  }

  /// Clears all authentication data (for testing/admin purposes)
  Future<void> clearAllAuth(Request request, Response response) async {
    // Clear all session data
    request.session.clear();

    // Clear all auth cookies
    response.cookieHandler.delete(_sessionKey);
    response.cookieHandler.delete(_rememberKey);
    response.cookieHandler.delete(_csrfKey);
    response.cookieHandler.delete('access_token');

    // Clear user context
    request.clearUser();
  }

  /// Gets login attempt information
  Map<String, dynamic> getLoginAttemptInfo(Request request) {
    final attempts = request.session.get(_loginAttemptsKey) as int? ?? 0;
    final lastAttempt = request.session.get(_lastLoginAttemptKey);
    final lockoutUntil = request.session.get(_lockoutUntilKey);

    return {
      'attempts': attempts,
      'max_attempts': _maxLoginAttempts,
      'remaining_attempts': _maxLoginAttempts - attempts,
      'last_attempt': lastAttempt,
      'is_locked': _isLockedOut(request),
      'lockout_until': lockoutUntil,
      'lockout_duration_minutes': _lockoutDuration.inMinutes,
    };
  }

  /// Verifies the authentication token (static method for convenience)
  static Future<Map<String, dynamic>> verifyToken() async {
    final authManager = Khadem.container.resolve<AuthManager>();
    final token =
        RequestContext.request.cookieHandler.get('access_token') ?? '';
    final userData = await authManager.verify(token);
    return userData;
  }

  /// Creates a new instance with default guard
  static WebAuthService create() {
    return WebAuthService();
  }

  /// Creates a new instance with specific guard
  static WebAuthService guard(String guardName) {
    return WebAuthService(guard: guardName);
  }
}
