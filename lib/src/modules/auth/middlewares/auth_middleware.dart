import 'dart:convert';

import 'package:khadem/src/modules/auth/core/request_auth.dart';

import '../../../contracts/http/middleware_contract.dart';
import '../../../core/http/request/request.dart';
import '../../../core/http/response/response.dart';
import '../contracts/authenticatable.dart';
import '../exceptions/auth_exception.dart';
import '../services/auth_manager.dart';

/// Enhanced Authentication Middleware for protecting routes
///
/// This middleware provides comprehensive authentication support with:
/// - Multiple token types (Bearer, Basic, API Key)
/// - Configurable error handling
/// - User data caching
/// - Role-based access control
/// - Flexible guard selection
///
/// Features:
/// - Bearer token extraction and validation
/// - Basic authentication support
/// - API key authentication
/// - Automatic user data attachment
/// - Comprehensive error handling
/// - Configurable through builder pattern
///
/// Example usage:
/// ```dart
/// // Bearer token authentication
/// final authMiddleware = AuthMiddleware.bearer();
///
/// // API key authentication
/// final apiMiddleware = AuthMiddleware.apiKey('X-API-Key');
///
/// // Basic auth with custom realm
/// final basicMiddleware = AuthMiddleware.basic(realm: 'MyApp');
///
/// // With role checking
/// final adminMiddleware = AuthMiddleware.bearer()
///   .withRoles(['admin'])
///   .withPermissions(['user.manage']);
///
/// // In routes configuration
/// router.get('/protected', handler, middleware: [authMiddleware]);
/// ```
class AuthMiddleware extends Middleware {
  /// Configuration for the middleware
  final AuthMiddlewareConfig _config;

  /// Creates an authentication middleware with custom configuration
  AuthMiddleware._(this._config, MiddlewareHandler handler)
      : super(handler, priority: _config.priority, name: _config.name);

  /// Creates a Bearer token authentication middleware
  factory AuthMiddleware.bearer({
    AuthManager? authManager,
    String guard = 'api',
    List<String> roles = const [],
    List<String> permissions = const [],
    bool cacheUser = false,
    MiddlewarePriority priority = MiddlewarePriority.auth,
    String name = 'auth-bearer',
  }) {
    final config = AuthMiddlewareConfig(
      authType: AuthType.bearer,
      authManager: authManager,
      guard: guard,
      roles: roles,
      permissions: permissions,
      cacheUser: cacheUser,
      priority: priority,
      name: name,
    );

    return AuthMiddleware._(config, _createHandler(config));
  }

  /// Creates a Basic authentication middleware
  factory AuthMiddleware.basic({
    AuthManager? authManager,
    String guard = 'api',
    String realm = 'Protected Area',
    List<String> roles = const [],
    List<String> permissions = const [],
    bool cacheUser = false,
    MiddlewarePriority priority = MiddlewarePriority.auth,
    String name = 'auth-basic',
  }) {
    final config = AuthMiddlewareConfig(
      authType: AuthType.basic,
      authManager: authManager,
      guard: guard,
      realm: realm,
      roles: roles,
      permissions: permissions,
      cacheUser: cacheUser,
      priority: priority,
      name: name,
    );

    return AuthMiddleware._(config, _createHandler(config));
  }

  /// Creates an API key authentication middleware
  factory AuthMiddleware.apiKey(
    String headerName, {
    AuthManager? authManager,
    String guard = 'api',
    List<String> roles = const [],
    List<String> permissions = const [],
    bool cacheUser = false,
    MiddlewarePriority priority = MiddlewarePriority.auth,
    String? name,
  }) {
    final config = AuthMiddlewareConfig(
      authType: AuthType.apiKey,
      authManager: authManager,
      guard: guard,
      apiKeyHeader: headerName,
      roles: roles,
      permissions: permissions,
      cacheUser: cacheUser,
      priority: priority,
      name: name ?? 'auth-api-key-$headerName',
    );

    return AuthMiddleware._(config, _createHandler(config));
  }

  /// Creates a custom authentication middleware
  factory AuthMiddleware.custom(
    AuthType authType, {
    required Future<Authenticatable?> Function(Request) authenticator,
    AuthManager? authManager,
    String guard = 'api',
    List<String> roles = const [],
    List<String> permissions = const [],
    bool cacheUser = false,
    MiddlewarePriority priority = MiddlewarePriority.auth,
    String name = 'auth-custom',
  }) {
    final config = AuthMiddlewareConfig(
      authType: authType,
      customAuthenticator: authenticator,
      authManager: authManager,
      guard: guard,
      roles: roles,
      permissions: permissions,
      cacheUser: cacheUser,
      priority: priority,
      name: name,
    );

    return AuthMiddleware._(config, _createHandler(config));
  }

  /// Creates the middleware handler based on configuration
  static MiddlewareHandler _createHandler(AuthMiddlewareConfig config) {
    return (Request req, Response res, NextFunction next) async {
      try {
        // Extract credentials based on auth type
        final credentials = await _extractCredentials(req, config);

        // Authenticate user
        final user = await _authenticateUser(credentials, config);

        // Check roles and permissions
        await _checkAuthorization(user, config);

        // Attach user data to request
        _attachUserToRequest(req, user, config);

        // Continue to next middleware
        await next();
      } catch (e) {
        await _handleAuthError(e, req, res, config);
      }
    };
  }

  /// Extracts credentials from request based on auth type
  static Future<Map<String, dynamic>> _extractCredentials(
    Request request,
    AuthMiddlewareConfig config,
  ) async {
    switch (config.authType) {
      case AuthType.bearer:
        return _extractBearerCredentials(request);
      case AuthType.basic:
        return _extractBasicCredentials(request);
      case AuthType.apiKey:
        return _extractApiKeyCredentials(request, config);
      case AuthType.custom:
        final user = await config.customAuthenticator!(request);
        return {'user': user};
    }
  }

  /// Extracts Bearer token credentials
  static Map<String, dynamic> _extractBearerCredentials(Request request) {
    final authHeader = request.header('authorization');

    if (authHeader == null || authHeader.isEmpty) {
      throw AuthException(
        'Missing authorization header. Please provide a Bearer token.',
      );
    }

    if (!authHeader.startsWith('Bearer ')) {
      throw AuthException(
        'Invalid authorization header format. Expected "Bearer <token>".',
      );
    }

    final token = authHeader.replaceFirst('Bearer ', '').trim();

    if (token.isEmpty) {
      throw AuthException(
        'Empty token provided in authorization header.',
      );
    }

    return {'token': token, 'type': 'bearer'};
  }

  /// Extracts Basic auth credentials
  static Map<String, dynamic> _extractBasicCredentials(Request request) {
    final authHeader = request.header('authorization');

    if (authHeader == null || !authHeader.startsWith('Basic ')) {
      throw AuthException(
        'Basic authentication required.',
      );
    }

    try {
      final credentials = authHeader.replaceFirst('Basic ', '');
      final decoded = String.fromCharCodes(base64Decode(credentials));
      final parts = decoded.split(':');

      if (parts.length != 2) {
        throw AuthException('Invalid Basic authentication format.');
      }

      return {
        'username': parts[0],
        'password': parts[1],
        'type': 'basic',
      };
    } catch (e) {
      throw AuthException('Invalid Basic authentication format.');
    }
  }

  /// Extracts API key credentials
  static Map<String, dynamic> _extractApiKeyCredentials(
    Request request,
    AuthMiddlewareConfig config,
  ) {
    final headerName = config.apiKeyHeader!;
    final apiKey = request.header(headerName.toLowerCase());

    if (apiKey == null || apiKey.isEmpty) {
      throw AuthException(
        'Missing API key in $headerName header.',
      );
    }

    return {'api_key': apiKey, 'type': 'api_key'};
  }

  /// Authenticates the user with extracted credentials
  static Future<Authenticatable> _authenticateUser(
    Map<String, dynamic> credentials,
    AuthMiddlewareConfig config,
  ) async {
    final authManager = config.authManager ?? _getDefaultAuthManager();

    switch (credentials['type']) {
      case 'bearer':
      case 'basic':
        return authManager.user(credentials['token'] ?? '');
      case 'api_key':
        // For API keys, we might need custom logic
        return authManager.user(credentials['api_key']);
      case 'user':
        return credentials['user'] as Authenticatable;
      default:
        throw AuthException('Unsupported authentication type.');
    }
  }

  /// Checks if user has required roles and permissions
  static Future<void> _checkAuthorization(
    Authenticatable user,
    AuthMiddlewareConfig config,
  ) async {
    final userData = user.toAuthArray();

    // Check roles
    if (config.roles.isNotEmpty) {
      final userRole = userData['role'] as String?;
      if (userRole == null || !config.roles.contains(userRole)) {
        throw AuthException(
          'Insufficient privileges. Required roles: ${config.roles.join(", ")}',
          statusCode: 403,
        );
      }
    }

    // Check permissions (this would need to be implemented based on your permission system)
    if (config.permissions.isNotEmpty) {
      final userPermissions =
          (userData['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
      final hasAllPermissions = config.permissions
          .every((permission) => userPermissions.contains(permission));

      if (!hasAllPermissions) {
        throw AuthException(
          'Insufficient permissions. Required: ${config.permissions.join(", ")}',
          statusCode: 403,
        );
      }
    }
  }

  /// Attaches user data to the request
  static void _attachUserToRequest(
    Request request,
    Authenticatable user,
    AuthMiddlewareConfig config,
  ) {
    request.setAuthenticatable(user);

    // Cache user data if enabled
    if (config.cacheUser) {
      request.setAttribute('cached_user', user);
    }
  }

  /// Handles authentication errors
  static Future<void> _handleAuthError(
    dynamic error,
    Request request,
    Response response,
    AuthMiddlewareConfig config,
  ) async {
    if (error is AuthException) {
      // For API requests, return JSON error
      if (_isApiRequest(request)) {
        response.status(error.statusCode).sendJson({
          'error': 'Authentication failed',
          'message': error.message,
          'code': error.statusCode,
        });
      } else {
        // For web requests, redirect or show error
        response.status(error.statusCode);
        // Let the error propagate for proper handling
        throw error;
      }
    } else {
      // Wrap unexpected errors
      final authError = AuthException(
        'Authentication failed: ${error.toString()}',
        statusCode: 500,
      );

      if (_isApiRequest(request)) {
        response.status(500).sendJson({
          'error': 'Internal server error',
          'message': 'Authentication service unavailable',
        });
      } else {
        throw authError;
      }
    }
  }

  /// Determines if this is an API request
  static bool _isApiRequest(Request request) {
    final accept = request.header('accept') ?? '';
    final contentType = request.header('content-type') ?? '';
    return accept.contains('application/json') ||
        contentType.contains('application/json');
  }

  /// Gets the default AuthManager instance
  static AuthManager _getDefaultAuthManager() {
    // Create AuthManager with default guard and 'users' provider
    return AuthManager(provider: 'users');
  }

  /// Builder methods for fluent configuration

  /// Adds required roles
  AuthMiddleware withRoles(List<String> roles) {
    final newConfig = _config.copyWith(roles: roles);
    return AuthMiddleware._(newConfig, _createHandler(newConfig));
  }

  /// Adds required permissions
  AuthMiddleware withPermissions(List<String> permissions) {
    final newConfig = _config.copyWith(permissions: permissions);
    return AuthMiddleware._(newConfig, _createHandler(newConfig));
  }

  /// Enables user caching
  AuthMiddleware withCaching([bool enabled = true]) {
    final newConfig = _config.copyWith(cacheUser: enabled);
    return AuthMiddleware._(newConfig, _createHandler(newConfig));
  }

  /// Sets custom guard
  AuthMiddleware withGuard(String guard) {
    final newConfig = _config.copyWith(guard: guard);
    return AuthMiddleware._(newConfig, _createHandler(newConfig));
  }
}

/// Configuration for AuthMiddleware
class AuthMiddlewareConfig {
  final AuthType authType;
  final AuthManager? authManager;
  final String guard;
  final String? realm;
  final String? apiKeyHeader;
  final Future<Authenticatable?> Function(Request)? customAuthenticator;
  final List<String> roles;
  final List<String> permissions;
  final bool cacheUser;
  final MiddlewarePriority priority;
  final String name;

  const AuthMiddlewareConfig({
    required this.authType,
    this.authManager,
    this.guard = 'api',
    this.realm,
    this.apiKeyHeader,
    this.customAuthenticator,
    this.roles = const [],
    this.permissions = const [],
    this.cacheUser = false,
    this.priority = MiddlewarePriority.auth,
    this.name = 'auth',
  });

  AuthMiddlewareConfig copyWith({
    AuthType? authType,
    AuthManager? authManager,
    String? guard,
    String? realm,
    String? apiKeyHeader,
    Future<Authenticatable?> Function(Request)? customAuthenticator,
    List<String>? roles,
    List<String>? permissions,
    bool? cacheUser,
    MiddlewarePriority? priority,
    String? name,
  }) {
    return AuthMiddlewareConfig(
      authType: authType ?? this.authType,
      authManager: authManager ?? this.authManager,
      guard: guard ?? this.guard,
      realm: realm ?? this.realm,
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
      customAuthenticator: customAuthenticator ?? this.customAuthenticator,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      cacheUser: cacheUser ?? this.cacheUser,
      priority: priority ?? this.priority,
      name: name ?? this.name,
    );
  }
}

/// Authentication types supported by the middleware
enum AuthType {
  bearer,
  basic,
  apiKey,
  custom,
}
