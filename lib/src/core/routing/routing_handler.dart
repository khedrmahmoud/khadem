import '../exception/exception_handler.dart';
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
        ExceptionHandler.handle(res, e, stackTrace);
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
