import '../../../contracts/http/middleware_contract.dart';
import '../../../core/http/request/request.dart';
import '../../../core/http/response/response.dart';
import '../services/auth_manager.dart';

/// Web Authentication Middleware
///
/// Middleware for protecting routes that require authentication.
/// Uses the AuthManager with the 'web' guard for session-based authentication.
class WebAuthMiddleware {
  /// Creates a new web authentication middleware
  ///
  /// [redirectTo] - Where to redirect unauthenticated users (default: '/login')
  /// [except] - Routes to exclude from authentication check
  /// [guard] - Auth guard to use (default: 'web')
  static Middleware create({
    String redirectTo = '/login',
    List<String> except = const [],
    String guard = 'web',
  }) {
    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // Check if route is excluded
        if (_isExcluded(request.path, except)) {
          return next();
        }

        // For web guard, check session-based authentication
        await _handleWebAuth(request, response, next, guard, redirectTo);
      },
      priority: MiddlewarePriority.auth,
      name: 'web-auth',
    );
  }

  /// Handles web authentication using sessions
  static Future<void> _handleWebAuth(
    Request request,
    Response response,
    NextFunction next,
    String guard,
    String redirectTo,
  ) async {
    try {
      // Get session ID from request
      final sessionId = request.sessionId;

      if (sessionId.isEmpty) {
        await _handleUnauthenticated(request, response, redirectTo);
        return;
      }

      // For web guard, check session-based authentication
      final authManager = AuthManager(guard: guard, provider: 'users');

      // Check if user is authenticated via session
      final isAuthenticated =
          await _checkWithGuard(authManager, guard, sessionId);

      if (!isAuthenticated) {
        await _handleUnauthenticated(request, response, redirectTo);
        return;
      }

      // Get user data
      final user = await authManager.userWithGuard(guard, sessionId);
      final userData = user.toAuthArray();

      // Attach user data to request
      _attachUserToRequest(request, userData);

      // Continue to next middleware
      await next();
    } catch (e) {
      // Authentication failed, clear session
      request.session.remove('user');
      request.session.remove('token');
      await _handleUnauthenticated(request, response, redirectTo);
    }
  }

  /// Checks authentication with a specific guard
  static Future<bool> _checkWithGuard(
    AuthManager authManager,
    String guardName,
    String token,
  ) async {
    try {
      final guard = authManager.getGuard(guardName);
      return await guard.check(token);
    } catch (e) {
      return false;
    }
  }

  /// Factory method for basic auth middleware
  static Middleware auth({
    String redirectTo = '/login',
    List<String> except = const [],
    String guard = 'web',
  }) {
    return create(redirectTo: redirectTo, except: except, guard: guard);
  }

  /// Factory method for guest-only middleware (redirects authenticated users)
  static Middleware guest({
    String redirectTo = '/dashboard',
    List<String> except = const [],
    String guard = 'web',
  }) {
    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // Check if route is excluded
        if (_isExcluded(request.path, except)) {
          return next();
        }

        // Check if user is authenticated
        final user = request.session.get('user');
        final token = request.session.get('token') as String?;

        if (user != null && token != null) {
          response.redirect(redirectTo);
          return;
        }

        // Continue to next middleware
        return next();
      },
      priority: MiddlewarePriority.auth,
      name: 'web-guest',
    );
  }

  /// Factory method for admin-only middleware
  static Middleware admin({
    String redirectTo = '/login',
    List<String> except = const [],
    String guard = 'web',
  }) {
    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // First check basic authentication
        if (_isExcluded(request.path, except)) {
          return next();
        }

        final user = request.session.get('user') as Map<String, dynamic>?;
        if (user == null) {
          await _handleUnauthenticated(request, response, redirectTo);
          return;
        }

        // Check admin role (simplified)
        final role = user['role'] as String?;
        if (role != 'admin') {
          request.session
              .flash('message', 'Access denied. Admin privileges required.');
          response.redirect('/dashboard');
          return;
        }

        await next();
      },
      priority: MiddlewarePriority.auth,
      name: 'web-admin',
    );
  }

  /// Checks if the current route should be excluded from authentication
  static bool _isExcluded(String path, List<String> except) {
    return except.any((route) => _matchesRoute(path, route));
  }

  /// Simple route matching (supports wildcards)
  static bool _matchesRoute(String path, String route) {
    if (route == path) return true;

    // Support for wildcards
    if (route.endsWith('*')) {
      final prefix = route.substring(0, route.length - 1);
      return path.startsWith(prefix);
    }

    return false;
  }

  /// Handles unauthenticated users
  static Future<void> _handleUnauthenticated(
    Request request,
    Response response,
    String redirectTo,
  ) async {
    // Store intended URL for redirect after login
    final intendedUrl = request.uri.toString();
    request.session.set('url.intended', intendedUrl);

    // Set flash message
    request.session.flash('message', 'Please log in to continue');

    // Redirect to login
    response.redirect(redirectTo);
  }

  /// Attaches user data to the request
  static void _attachUserToRequest(Request request, Map<String, dynamic> user) {
    request.setAttribute('user', user);
    request.setAttribute('userId', user['id']);
    request.setAttribute('isAuthenticated', true);
    request.setAttribute('isGuest', false);
  }
}
