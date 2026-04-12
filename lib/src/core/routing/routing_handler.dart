import '../../application/khadem.dart';
import '../../contracts/exceptions/exception_handler_contract.dart';
import '../http/request/request.dart';
import '../http/request/request_handler.dart';
import '../http/response/response.dart';

/// Handles route handler wrapping and execution.
class RouteHandler {
  /// Wraps a route handler with exception handling.
  RequestHandler wrapWithExceptionHandler(RequestHandler handler) {
    return (Request req, Response res) async {
      try {
        await handler(req, res);
      } catch (e, stackTrace) {
        final exceptionHandler = Khadem.make<ExceptionHandlerContract>();
        final result = await exceptionHandler.handle(e, stackTrace);

        if (!res.sent) {
          res
              .status(result.statusCode)
              .problem(
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
    };
  }

  /// Wraps multiple handlers with exception handling.
  List<RequestHandler> wrapHandlers(List<RequestHandler> handlers) {
    return handlers.map(wrapWithExceptionHandler).toList();
  }

  /// Executes a handler with proper error handling.
  Future<void> executeHandler(
    RequestHandler handler,
    Request req,
    Response res,
  ) async {
    final wrappedHandler = wrapWithExceptionHandler(handler);
    await wrappedHandler(req, res);
  }
}
