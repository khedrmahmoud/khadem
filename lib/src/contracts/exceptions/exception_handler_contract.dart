import '../../core/exception/error_result.dart';

/// Contract for handling exceptions in the application.
abstract interface class ExceptionHandlerContract {
  /// Handle an exception and return a standardized error result.
  Future<ErrorResult> handle(Object error, [StackTrace? stackTrace]);

  /// Register a custom handler for a specific exception type.
  void register<T extends Object>(
    Future<ErrorResult> Function(T error, StackTrace? stackTrace) handler,
  );
}
