import 'dart:async';

import '../../contracts/exceptions/app_exception.dart';
import '../../contracts/exceptions/exception_handler_contract.dart';
import '../http/context/request_context.dart';
import 'error_result.dart';
import 'exception_reporter.dart';

/// Handles exceptions raised in the application and returns standardized error results.
///
/// This class provides comprehensive exception handling with:
/// - Automatic RFC 7807 Problem Details mapping
/// - Request context inclusion in error reports (if available)
/// - Development vs production error detail levels
/// - Custom error mapping
///
/// The handler is protocol-agnostic and returns an [ErrorResult] which can be
/// formatted by the transport layer (HTTP, Socket, etc.).
class ExceptionHandler implements ExceptionHandlerContract {
  /// Whether to show detailed error information in responses
  bool _showDetailedErrors = false;

  /// Whether to include stack traces in development responses
  bool _includeStackTracesInResponse = false;

  /// Registry of custom exception handlers
  final Map<Type, Future<ErrorResult> Function(dynamic, StackTrace?)>
      _handlers = {};

  /// Configure exception handling settings
  void configure({
    bool showDetailedErrors = true,
    bool includeStackTracesInResponse = false,
  }) {
    _showDetailedErrors = showDetailedErrors;
    _includeStackTracesInResponse = includeStackTracesInResponse;
  }

  @override
  void register<T extends Object>(
    Future<ErrorResult> Function(T error, StackTrace? stackTrace) handler,
  ) {
    _handlers[T] = (err, stack) => handler(err as T, stack);
  }

  @override
  Future<ErrorResult> handle(
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    // Build context for reporting
    final context = _buildRequestContext();

    // Report the exception
    if (error is AppException) {
      ExceptionReporter.reportAppException(error, stackTrace, context);
    } else {
      ExceptionReporter.reportException(error, stackTrace, context);
    }

    // Check for custom handler
    if (_handlers.containsKey(error.runtimeType)) {
      return _handlers[error.runtimeType]!(error, stackTrace);
    }

    // Default handling
    if (error is AppException) {
      return _mapAppException(error, stackTrace);
    } else {
      return _mapGenericException(error, stackTrace);
    }
  }

  /// Map AppException to ErrorResult
  ErrorResult _mapAppException(
    AppException error,
    StackTrace? stackTrace,
  ) {
    final isServerError = error.statusCode >= 500;
    final detail = (!_showDetailedErrors && isServerError)
        ? 'An internal error occurred.'
        : error.message;
    final includeDetails = error.statusCode < 500 || _showDetailedErrors;

    return ErrorResult(
      statusCode: error.statusCode,
      title: error.title,
      message: detail,
      type: error.type,
      instance: error.instance,
      details: includeDetails ? error.details : null,
      stackTrace: (_showDetailedErrors && _includeStackTracesInResponse)
          ? stackTrace
          : null,
    );
  }

  /// Map generic exception to ErrorResult
  ErrorResult _mapGenericException(
    Object error,
    StackTrace? stackTrace,
  ) {
    return ErrorResult(
      statusCode: 500,
      title: 'Internal Server Error',
      message: _showDetailedErrors
          ? error.toString()
          : 'An unexpected error occurred.',
      stackTrace: (_showDetailedErrors && _includeStackTracesInResponse)
          ? stackTrace
          : null,
    );
  }

  /// Build request context for error reporting
  Map<String, dynamic> _buildRequestContext() {
    final context = <String, dynamic>{};

    try {
      // We try to access RequestContext, but if it fails or isn't available, we ignore it.
      if (RequestContext.hasRequest) {
        final request = RequestContext.request;
        context['request'] = {
          'method': request.method,
          'url': request.uri.toString(),
          'headers': request.headers,
          'user_agent': request.headers.get('user-agent'),
        };
      }
    } catch (e) {
      // Request context not available
    }

    return context;
  }
}
