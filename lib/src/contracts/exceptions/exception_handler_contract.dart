import '../../core/http/response/response.dart';

/// Contract for handling exceptions in the application.
abstract interface class ExceptionHandlerContract {
  /// Handle an exception and send appropriate response.
  Future<void> handle(
    Response response,
    Object error, [
    StackTrace? stackTrace,
  ]);

  /// Register a custom handler for a specific exception type.
  void register<T extends Object>(
    Future<void> Function(Response response, T error, StackTrace? stackTrace)
        handler,
  );
}
