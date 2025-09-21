import '../../contracts/http/middleware_contract.dart';
import '../../core/exception/exception_handler.dart';

import '../../core/http/request/request.dart';
import '../../core/http/response/response.dart';

/// A global middleware to catch and handle all uncaught exceptions.
class ExceptionMiddleware implements Middleware {
  Future<void> handle(Request req, Response res, NextFunction next) async {
    try {
      await next();
    } catch (error, stackTrace) {
      // Handle specific exception types
      ExceptionHandler.handle(res, error, stackTrace);
    }
  }

  @override
  MiddlewareHandler get handler => handle;

  @override
  String get name => "ExceptionMiddleware";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.terminating;
}
