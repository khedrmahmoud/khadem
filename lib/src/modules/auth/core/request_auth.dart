import '../../../application/khadem.dart';
import '../../../core/http/request/request.dart';
import '../contracts/authenticatable.dart';
import '../exceptions/auth_exception.dart';
import '../services/auth_manager.dart';

/// Enhanced authentication extension for HTTP requests
///
/// This extension provides comprehensive authentication functionality
/// for HTTP requests, including user management, role checking,
/// permissions, and security features.
extension RequestAuth on Request {
  /// Returns the currently authenticated user data (if any).
  Map<String, dynamic>? get user => attribute<Map<String, dynamic>>('user');

  /// Returns the currently authenticated Authenticatable instance (if available).
  Authenticatable? get authenticatable =>
      attribute<Authenticatable>('authenticatable');

  /// Returns the ID of the authenticated user (if available).
  dynamic get userId => user?['id'] ?? authenticatable?.getAuthIdentifier();

  /// Returns the email of the authenticated user (if available).
  String? get userEmail => user?['email'] as String?;

  /// Returns the name of the authenticated user (if available).
  String? get userName => user?['name'] as String?;

  /// Returns true if a user is authenticated.
  bool get isAuthenticated => user != null || authenticatable != null;

  /// Returns true if no user is authenticated.
  bool get isGuest => !isAuthenticated;

  /// Returns true if the user has admin privileges.
  bool get isAdmin => hasRole('admin') || hasRole('super_admin');

  /// Returns true if the user has super admin privileges.
  bool get isSuperAdmin => hasRole('super_admin');

  /// Sets the authenticated user from an Authenticatable instance.
  void setAuthenticatable(Authenticatable authenticatable) {
    setUserAuthenticatable(authenticatable);
  }

  /// Sets the authenticated user from an Authenticatable instance.
  void setUserAuthenticatable(Authenticatable user) {
    setAttribute('user', user.toAuthArray());
    setAttribute('authenticatable', user);
    setAttribute('userId', user.getAuthIdentifier());
    setAttribute('isAuthenticated', true);
    setAttribute('isGuest', false);
  }

  /// Sets the authenticated user from a map (backward compatibility).
  void setUser(Map<String, dynamic> userData) {
    final authenticatable = MapAuthenticatable(userData);
    setUserAuthenticatable(authenticatable);
  }

  /// Clears the authenticated user.
  void clearUser() {
    removeAttribute('user');
    removeAttribute('authenticatable');
    removeAttribute('userId');
    setAttribute('isAuthenticated', false);
    setAttribute('isGuest', true);
  }

  /// Checks if the user has a specific role.
  bool hasRole(String role) {
    // First check the map representation
    final user = this.user;
    if (user != null) {
      final roles = user['roles'];
      if (roles is List<dynamic>) {
        return roles.contains(role);
      }
    }

    // If no map data, check if we have an Authenticatable instance
    // Note: The Authenticatable interface doesn't define roles,
    // so this would need to be implemented by subclasses
    return false;
  }

  /// Checks if the user has any of the specified roles.
  bool hasAnyRole(List<String> roles) {
    return roles.any(hasRole);
  }

  /// Checks if the user has all of the specified roles.
  bool hasAllRoles(List<String> roles) {
    return roles.every(hasRole);
  }

  /// Checks if the user has a specific permission.
  bool hasPermission(String permission) {
    // First check the map representation
    final user = this.user;
    if (user != null) {
      // Check roles for wildcard permissions first
      final roles = user['roles'];
      if (roles is List<dynamic>) {
        // Check for admin roles that have all permissions
        if (roles.contains('admin') || roles.contains('super_admin')) {
          return true;
        }
      }

      // Check explicit permissions
      final permissions = user['permissions'];
      if (permissions is List<dynamic>) {
        return permissions.contains(permission);
      }
    }

    // If no map data, check if we have an Authenticatable instance
    // Note: The Authenticatable interface doesn't define permissions,
    // so this would need to be implemented by subclasses
    return false;
  }

  /// Checks if the user has any of the specified permissions.
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any(hasPermission);
  }

  /// Checks if the user has all of the specified permissions.
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every(hasPermission);
  }

  /// Checks if the user owns a resource (by comparing user ID).
  bool ownsResource(dynamic resourceOwnerId) {
    if (isGuest) return false;
    return userId == resourceOwnerId;
  }

  /// Checks if the user can access admin-only resources.
  bool canAccessAdmin() {
    return isAuthenticated && (isAdmin || isSuperAdmin);
  }

  /// Gets user metadata/custom fields.
  dynamic getUserMeta(String key) {
    final user = this.user;
    if (user == null) return null;

    final meta = user['meta'];
    if (meta is Map<String, dynamic>) {
      return meta[key];
    }

    return null;
  }

  /// Sets user metadata/custom fields.
  void setUserMeta(String key, dynamic value) {
    final user = this.user;
    if (user == null) return;

    final meta = user['meta'] as Map<String, dynamic>? ?? {};
    meta[key] = value;
    user['meta'] = meta;

    // Update the stored user data
    setAttribute('user', user);
  }

  /// Gets the user's authentication guard name.
  String? get guard => attribute<String>('auth_guard');

  /// Sets the user's authentication guard name.
  void setGuard(String guardName) {
    setAttribute('auth_guard', guardName);
  }

  /// Gets the user's authentication token (if available).
  String? get token => attribute<String>('auth_token');

  /// Sets the user's authentication token.
  void setToken(String token) {
    setAttribute('auth_token', token);
  }

  /// Checks if the current request is attempting authentication.
  bool get isAttemptingAuth {
    final authHeader = header('authorization');

    // Check query parameters for credentials
    final hasEmailInQuery = query['email'] != null;
    final hasUsernameInQuery = query['username'] != null;

    // Try to check body parameters, but don't fail if body isn't parsed
    bool hasCredentialsInBody = false;
    try {
      hasCredentialsInBody =
          input('email') != null || input('username') != null;
    } catch (e) {
      // Body not parsed yet, can't check body parameters
    }

    return authHeader != null ||
        hasEmailInQuery ||
        hasUsernameInQuery ||
        hasCredentialsInBody;
  }

  /// Gets the Bearer token from the Authorization header.
  String? get bearerToken {
    final authHeader = header('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    return authHeader.substring(7).trim();
  }

  /// Validates the current user's session/token.
  Future<bool> validateAuth() async {
    if (isGuest) return false;

    try {
      final authManager = Khadem.container.resolve<AuthManager>();
      final token = this.token ?? bearerToken;

      if (token == null || token.isEmpty) return false;

      return await authManager.check(token);
    } catch (e) {
      return false;
    }
  }

  /// Refreshes the current user's authentication.
  Future<Map<String, dynamic>?> refreshAuth() async {
    if (isGuest) return null;

    try {
      final authManager = Khadem.container.resolve<AuthManager>();
      final refreshToken = attribute<String>('refresh_token');

      if (refreshToken == null) return null;

      final response = await authManager.refresh(refreshToken);
      return response.toMap();
    } catch (e) {
      return null;
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    if (isGuest) return;

    try {
      final authManager = Khadem.container.resolve<AuthManager>();
      final token = this.token ?? bearerToken;

      if (token != null && token.isNotEmpty) {
        await authManager.logout(token);
      }

      // Clear session data
      clearSession();
      clearUser();
    } catch (e) {
      // Even if logout fails, clear local state
      clearSession();
      clearUser();
    }
  }

  /// Logs out the user from all devices.
  Future<void> logoutAllDevices() async {
    if (isGuest) return;

    try {
      final authManager = Khadem.container.resolve<AuthManager>();
      final token = this.token ?? bearerToken;

      if (token != null && token.isNotEmpty) {
        await authManager.logoutAll(token);
      }
      // Clear session data
      clearSession();
      clearUser();
    } catch (e) {
      // Even if logout fails, clear local state
      clearSession();
      clearUser();
    }
  }

  /// Checks if the user was recently authenticated (within last 5 minutes).
  bool get wasRecentlyAuthenticated {
    final authTime = attribute<DateTime>('auth_time');
    if (authTime == null) return false;

    return DateTime.now().difference(authTime).inMinutes < 5;
  }

  /// Records the authentication time.
  void recordAuthTime() {
    setAttribute('auth_time', DateTime.now());
  }

  /// Gets the user's IP address for security logging.
  String get clientIp {
    // Check for forwarded headers first (proxy/load balancer)
    final forwarded = header('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }

    final realIp = header('x-real-ip');
    if (realIp != null) return realIp;

    // Fallback to connection info
    try {
      return raw.connectionInfo?.remoteAddress.address ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Gets the user's User-Agent for security logging.
  String get userAgent => header('user-agent') ?? 'unknown';

  /// Checks if the request is from a suspicious source.
  bool get isSuspicious {
    // Check for common security indicators
    final ua = userAgent.toLowerCase();
    final suspiciousPatterns = [
      'bot',
      'crawler',
      'spider',
      'scraper',
      'sqlmap',
      'nmap',
      'masscan',
      'zmap',
    ];

    return suspiciousPatterns.any((pattern) => ua.contains(pattern));
  }

  /// Gets authentication context for logging/auditing.
  Map<String, dynamic> get authContext {
    return {
      'user_id': userId,
      'user_email': userEmail,
      'ip_address': clientIp,
      'user_agent': userAgent,
      'is_authenticated': isAuthenticated,
      'guard': guard,
      'timestamp': DateTime.now().toIso8601String(),
      'path': path,
      'method': method,
    };
  }

  /// Requires authentication - throws exception if not authenticated.
  void requireAuth([String? message]) {
    if (isGuest) {
      throw AuthException(message ?? 'Authentication required');
    }
  }

  /// Requires admin privileges - throws exception if not admin.
  void requireAdmin([String? message]) {
    requireAuth();
    if (!isAdmin) {
      throw AuthException(message ?? 'Admin privileges required',
          statusCode: 403,);
    }
  }

  /// Requires super admin privileges - throws exception if not super admin.
  void requireSuperAdmin([String? message]) {
    requireAuth();
    if (!isSuperAdmin) {
      throw AuthException(message ?? 'Super admin privileges required',
          statusCode: 403,);
    }
  }

  /// Requires a specific role - throws exception if user doesn't have it.
  void requireRole(String role, [String? message]) {
    requireAuth();
    if (!hasRole(role)) {
      throw AuthException(message ?? 'Role "$role" required', statusCode: 403);
    }
  }

  /// Requires a specific permission - throws exception if user doesn't have it.
  void requirePermission(String permission, [String? message]) {
    requireAuth();
    if (!hasPermission(permission)) {
      throw AuthException(message ?? 'Permission "$permission" required',
          statusCode: 403,);
    }
  }

  /// Requires ownership of a resource.
  void requireOwnership(dynamic resourceOwnerId, [String? message]) {
    requireAuth();
    if (!ownsResource(resourceOwnerId)) {
      throw AuthException(message ?? 'Access denied: not the owner',
          statusCode: 403,);
    }
  }

  /// Removes an attribute from the request.
  void removeAttribute(String key) {
    // Since RequestParams doesn't have a remove method, we set it to null
    setAttribute(key, null);
  }
}

/// Simple implementation of Authenticatable for map-based user data.
/// This provides backward compatibility for code that uses maps directly.
class MapAuthenticatable implements Authenticatable {
  final Map<String, dynamic> _data;

  MapAuthenticatable(this._data);

  @override
  dynamic getAuthIdentifier() => _data['id'];

  @override
  String getAuthIdentifierName() => 'id';

  @override
  String? getAuthPassword() => _data['password'];

  @override
  Map<String, dynamic> toAuthArray() => _data;
}
