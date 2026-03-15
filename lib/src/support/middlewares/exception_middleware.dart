import '../../application/khadem.dart';
import '../../contracts/exceptions/exception_handler_contract.dart';
import '../../contracts/http/middleware_contract.dart';
import '../../contracts/http/response_contract.dart';

import '../../core/http/request/request.dart';

/// A global middleware to catch and handle all uncaught exceptions.
class ExceptionMiddleware implements Middleware {
  Future<void> handle(
    Request req,
    ResponseContract res,
    NextFunction next,
  ) async {
    try {
      await next();
    } catch (error, stackTrace) {
      // Handle specific exception types
      final handler = Khadem.make<ExceptionHandlerContract>();
      final result = await handler.handle(error, stackTrace);

      // Send response
      res.status(result.statusCode).problem(
        title: result.title,
        status: result.statusCode,
        detail: result.message,
        type: result.type,
        instance: result.instance,
        extensions: {
          if (result.details != null) 'details': result.details,
          if (result.stackTrace != null)
            'stack_trace': result.stackTrace.toString(),
          ...result.extensions,
        },
      );
    }
  }

  @override
  MiddlewareHandler get handler => handle;

  @override
  String get name => "ExceptionMiddleware";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.terminating;
}
