import '../../application/khadem.dart';
import '../../contracts/exceptions/exception_handler_contract.dart';
import '../../contracts/http/middleware_contract.dart';

import '../../core/http/request/request.dart';
import '../../core/http/response/response.dart';

/// A global middleware to catch and handle all uncaught exceptions.
class ExceptionMiddleware implements Middleware {
  Future<void> handle(Request req, Response res, NextFunction next) async {
    try {
      await next();
    } catch (error, stackTrace) {
      // Handle specific exception types
      final handler = Khadem.make<ExceptionHandlerContract>();
      await handler.handle(res, error, stackTrace);
    }
  }

  @override
  MiddlewareHandler get handler => handle;

  @override
  String get name => "ExceptionMiddleware";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.terminating;
}
