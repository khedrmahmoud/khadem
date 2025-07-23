// 📁 lib/src/core/http/middleware/auth_middleware.dart

import '../../../contracts/http/middleware_contract.dart';
import '../../../core/http/request/request.dart';
import '../../../core/http/response/response.dart';
import '../../../application/khadem.dart';

import '../exceptions/auth_exception.dart';

/// Middleware that checks for a valid Authorization token in the request.
class AuthMiddleware implements Middleware {
  Future<void> handle(Request req, Response res, NextFunction next) async {
    final authHeader = req.headers['Authorization']?.first;
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw AuthException('Missing or invalid authorization header.');
    }

    final token = authHeader.replaceFirst('Bearer ', '').trim();
    final user = await Khadem.auth.verify(token);
    // Attach user info to request for later use in controllers
    req.attributes['user'] = user;

    await next();
  }

  @override
  MiddlewareHandler get handler => handle;

  @override
  String get name => "AuthMiddleware";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.auth;
}
