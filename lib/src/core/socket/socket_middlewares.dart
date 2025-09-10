import 'dart:async';
import '../../contracts/socket/socket_middleware.dart';
import '../socket/socket_client.dart';

/// Middleware to check if client is authorized
class AuthMiddleware extends SocketMiddleware {
  AuthMiddleware()
      : super.message(
          _handleAuth,
          priority: SocketMiddlewarePriority.auth,
          name: 'auth-middleware',
        );

  static FutureOr<void> _handleAuth(
    SocketClient client,
    dynamic message,
    SocketNextFunction next,
  ) async {
    if (!client.isAuthorized) {
      client.send('error', {
        'type': 'unauthorized',
        'message': 'Authentication required',
      });
      return;
    }

    await next();
  }
}

/// Middleware to check for specific permissions
class PermissionMiddleware extends SocketMiddleware {
  final String permission;

  PermissionMiddleware(this.permission)
      : super.message(
          (client, message, next) => _handlePermission(client, message, next, permission),
          priority: SocketMiddlewarePriority.auth,
          name: 'permission-middleware-$permission',
        );

  static FutureOr<void> _handlePermission(
    SocketClient client,
    dynamic message,
    SocketNextFunction next,
    String permission,
  ) async {
    // Get user permissions from client context
    final user = client.get('user');
    if (user == null) {
      client.send('error', {
        'type': 'unauthorized',
        'message': 'User not found in session',
      });
      return;
    }

    final permissions = user['permissions'] as List<dynamic>? ?? [];

    if (!permissions.contains(permission)) {
      client.send('error', {
        'type': 'forbidden',
        'message': 'Insufficient permissions: $permission required',
      });
      return;
    }

    await next();
  }
}

/// Middleware to rate limit requests
class RateLimitMiddleware extends SocketMiddleware {
  final int maxRequests;
  final Duration window;
  final Map<String, List<DateTime>> _requestHistory = {};

  RateLimitMiddleware(this.maxRequests, this.window)
      : super.message(
          _handleRateLimit,
          priority: SocketMiddlewarePriority.preprocessing,
          name: 'rate-limit-middleware',
        );

  static FutureOr<void> _handleRateLimit(
    SocketClient client,
    dynamic message,
    SocketNextFunction next,
  ) async {
    final middleware = message as RateLimitMiddleware;
    final clientId = client.id;
    final now = DateTime.now();

    // Clean old requests
    middleware._requestHistory[clientId]?.removeWhere(
      (time) => now.difference(time) > middleware.window,
    );

    // Check rate limit
    final requests = middleware._requestHistory[clientId] ?? [];
    if (requests.length >= middleware.maxRequests) {
      client.send('error', {
        'type': 'rate_limited',
        'message': 'Too many requests. Try again later.',
        'retry_after': middleware.window.inSeconds,
      });
      return;
    }

    // Add current request
    middleware._requestHistory.putIfAbsent(clientId, () => []).add(now);

    await next();
  }
}

/// Middleware to validate message structure
class ValidationMiddleware extends SocketMiddleware {
  final bool Function(dynamic message) validator;
  final String errorMessage;

  ValidationMiddleware(this.validator, {this.errorMessage = 'Invalid message format'})
      : super.message(
          (client, message, next) => _handleValidation(client, message, next, validator, errorMessage),
          priority: SocketMiddlewarePriority.preprocessing,
          name: 'validation-middleware',
        );

  static FutureOr<void> _handleValidation(
    SocketClient client,
    dynamic message,
    SocketNextFunction next,
    bool Function(dynamic message) validator,
    String errorMessage,
  ) async {
    if (!validator(message)) {
      client.send('error', {
        'type': 'validation_error',
        'message': errorMessage,
      });
      return;
    }

    await next();
  }
}
