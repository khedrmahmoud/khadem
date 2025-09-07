import 'dart:async';

import 'package:khadem/khadem_dart.dart';

/// Web Authentication Middleware
///
/// Middleware for protecting routes that require authentication.
/// Integrates with WebAuthService for session-based authentication.
class WebAuthMiddleware {
  /// Creates a new web authentication middleware
  ///
  /// [redirectTo] - Where to redirect unauthenticated users (default: '/login')
  /// [except] - Routes to exclude from authentication check
  /// [regenerateSession] - Whether to regenerate session on each request
  /// [guard] - Auth guard to use
  static Middleware create({
    String redirectTo = '/login',
    List<String> except = const [],
    bool regenerateSession = true,
    String? guard,
  }) {
    final authService = WebAuthService(guard: guard);

    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // Check if route is excluded
        if (_isExcluded(request.path, except)) {
          return next();
        }

        // Check authentication
        if (!authService.isAuthenticated(request)) {
          // Handle unauthenticated user
          await _handleUnauthenticated(request, response, redirectTo);
          return;
        }

        // Check if session needs regeneration
        if (regenerateSession && request.session.shouldRegenerate()) {
          request.session.regenerateId();
        }

        // Check if session is expiring soon and extend if needed
        if (request.session.isExpiringSoon(const Duration(minutes: 10))) {
          request.session.setTimeout(const Duration(minutes: 30));
        }

        // Ensure user context is set
        await _ensureUserContext(request, response, authService, redirectTo);

        // Continue to next middleware
        return next();
      },
      priority: MiddlewarePriority.auth,
      name: 'web-auth',
    );
  }

  /// Factory method for basic auth middleware
  static Middleware auth({
    String redirectTo = '/login',
    List<String> except = const [],
  }) {
    return create(redirectTo: redirectTo, except: except);
  }

  /// Factory method for guest-only middleware (redirects authenticated users)
  static Middleware guest({
    String redirectTo = '/dashboard',
    List<String> except = const [],
  }) {
    final authService = WebAuthService.create();

    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // Check if route is excluded
        if (_isExcluded(request.path, except)) {
          return next();
        }

        // If user is authenticated, redirect
        if (authService.isAuthenticated(request)) {
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
  }) {
    final authService = WebAuthService.create();

    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // First check basic authentication
        if (_isExcluded(request.path, except)) {
          return next();
        }

        if (!authService.isAuthenticated(request)) {
          await _handleUnauthenticated(request, response, redirectTo);
          return;
        }

        // Check admin role
        if (!request.hasRole('admin')) {
          request.session.flash('message', 'Access denied. Admin privileges required.');
          request.session.flash('message_type', 'error');
          response.redirect('/dashboard');
          return;
        }

        return next();
      },
      priority: MiddlewarePriority.auth,
      name: 'web-admin',
    );
  }

  /// Factory method for role-based middleware
  static Middleware roles(
    List<String> roles, {
    String redirectTo = '/login',
    List<String> except = const [],
    bool requireAll = false,
  }) {
    final authService = WebAuthService.create();

    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // First check basic authentication
        if (_isExcluded(request.path, except)) {
          return next();
        }

        if (!authService.isAuthenticated(request)) {
          await _handleUnauthenticated(request, response, redirectTo);
          return;
        }

        // Check roles
        bool hasAccess;
        if (requireAll) {
          hasAccess = request.hasAllRoles(roles);
        } else {
          hasAccess = request.hasAnyRole(roles);
        }

        if (!hasAccess) {
          request.session.flash('message', 'Access denied. Insufficient privileges.');
          request.session.flash('message_type', 'error');
          response.redirect('/dashboard');
          return;
        }

        return next();
      },
      priority: MiddlewarePriority.auth,
      name: 'web-roles',
    );
  }

  /// Factory method for permission-based middleware
  static Middleware permissions(
    List<String> permissions, {
    String redirectTo = '/login',
    List<String> except = const [],
    bool requireAll = false,
  }) {
    final authService = WebAuthService.create();

    return Middleware(
      (Request request, Response response, NextFunction next) async {
        // First check basic authentication
        if (_isExcluded(request.path, except)) {
          return next();
        }

        if (!authService.isAuthenticated(request)) {
          await _handleUnauthenticated(request, response, redirectTo);
          return;
        }

        // Check permissions
        final user = request.user;
        if (user == null) {
          await _handleUnauthenticated(request, response, redirectTo);
          return;
        }

        final userPermissions = List<String>.from(user['permissions'] ?? []);

        bool hasAccess;
        if (requireAll) {
          hasAccess = permissions.every((perm) => userPermissions.contains(perm));
        } else {
          hasAccess = permissions.any((perm) => userPermissions.contains(perm));
        }

        if (!hasAccess) {
          request.session.flash('message', 'Access denied. Insufficient permissions.');
          request.session.flash('message_type', 'error');
          response.redirect('/dashboard');
          return;
        }

        return next();
      },
      priority: MiddlewarePriority.auth,
      name: 'web-permissions',
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
    request.session.flash('message_type', 'warning');

    // Redirect to login
    response.redirect(redirectTo);
  }

  /// Ensures user context is properly set
  static Future<void> _ensureUserContext(
    Request request,
    Response response,
    WebAuthService authService,
    String redirectTo,
  ) async {
    // If user is not set in request context, try to get from session
    if (request.user == null) {
      try {
        final user = await authService.getCurrentUser(request);
        if (user != null) {
          request.setUser(user);
        }
      } catch (e) {
        // If token verification fails, logout user
        await authService.logout(request, response);
        await _handleUnauthenticated(request, response, redirectTo);
        return;
      }
    }
  }
}
