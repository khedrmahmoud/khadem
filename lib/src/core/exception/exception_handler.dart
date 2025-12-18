import 'dart:async';

import '../../contracts/exceptions/app_exception.dart';
import '../../contracts/exceptions/exception_handler_contract.dart';
import '../http/context/request_context.dart';
import '../http/context/response_context.dart';
import '../http/response/response.dart';
import 'exception_reporter.dart';

/// Handles exceptions raised in the application and sends appropriate responses.
///
/// This class provides comprehensive exception handling with:
/// - Automatic RFC 7807 Problem Details response formatting
/// - Request context inclusion in error reports
/// - Development vs production error detail levels
/// - Custom error response formatting
/// - Support for different content types (JSON, HTML, XML)
///
/// The handler automatically detects the response format and sends
/// appropriate error responses based on the request's Accept header.
class ExceptionHandler implements ExceptionHandlerContract {
  /// Whether to show detailed error information in responses
  bool _showDetailedErrors = false;

  /// Whether to include stack traces in development responses
  bool _includeStackTracesInResponse = false;

  /// Registry of custom exception handlers
  final Map<Type, Future<void> Function(Response, dynamic, StackTrace?)>
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
    Future<void> Function(Response response, T error, StackTrace? stackTrace)
        handler,
  ) {
    _handlers[T] = (res, err, stack) => handler(res, err as T, stack);
  }

  @override
  Future<void> handle(
    Response? response,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    final res = response ?? ResponseContext.response;

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
      await _handlers[error.runtimeType]!(res, error, stackTrace);
      return;
    }

    // Default handling
    if (error is AppException) {
      await _sendAppExceptionResponse(res, error, stackTrace);
    } else {
      await _sendGenericExceptionResponse(res, error, stackTrace);
    }
  }

  /// Send response for AppException
  Future<void> _sendAppExceptionResponse(
    Response res,
    AppException error,
    StackTrace? stackTrace,
  ) async {
    if (res.sent) return;

    // Content Negotiation
    String? acceptHeader;
    try {
      acceptHeader = RequestContext.request.headers.get('accept');
    } catch (_) {}

    if (acceptHeader != null && acceptHeader.contains('text/html')) {
      _sendHtmlAppExceptionResponse(res, error, stackTrace);
      return;
    }

    final isServerError = error.statusCode >= 500;
    final detail = (!_showDetailedErrors && isServerError)
        ? 'An internal error occurred.'
        : error.message;
    final includeDetails = error.statusCode < 500 || _showDetailedErrors;

    // Default to RFC 7807 JSON
    res.status(error.statusCode).problem(
      type: error.type,
      title: error.title,
      detail: detail,
      instance: error.instance,
      status: error.statusCode,
      extensions: {
        if (includeDetails && error.details != null) 'details': error.details,
        if (_showDetailedErrors &&
            _includeStackTracesInResponse &&
            stackTrace != null)
          'stack_trace': stackTrace.toString(),
      },
    );
  }

  /// Send response for generic exception
  Future<void> _sendGenericExceptionResponse(
    Response res,
    Object error,
    StackTrace? stackTrace,
  ) async {
    if (res.sent) return;

    String? acceptHeader;
    try {
      acceptHeader = RequestContext.request.headers.get('accept');
    } catch (_) {}

    if (acceptHeader != null && acceptHeader.contains('text/html')) {
      _sendHtmlGenericExceptionResponse(res, error, stackTrace);
      return;
    }

    res.status(500).problem(
      type: 'about:blank',
      title: 'Internal Server Error',
      status: 500,
      detail: _showDetailedErrors
          ? error.toString()
          : 'An unexpected error occurred.',
      extensions: {
        if (_showDetailedErrors &&
            _includeStackTracesInResponse &&
            stackTrace != null)
          'stack_trace': stackTrace.toString(),
      },
    );
  }

  /// Send HTML response for AppException
  void _sendHtmlAppExceptionResponse(
    Response res,
    AppException error,
    StackTrace? stackTrace,
  ) {
    final html = _buildHtmlErrorResponse(
      error,
      stackTrace,
      statusCode: error.statusCode,
      title: error.title,
      message: error.message,
    );
    res.status(error.statusCode).header('Content-Type', 'text/html').send(html);
  }

  /// Send HTML response for generic exception
  void _sendHtmlGenericExceptionResponse(
    Response res,
    Object error,
    StackTrace? stackTrace,
  ) {
    final html = _buildHtmlErrorResponse(
      error,
      stackTrace,
      title: 'Internal Server Error',
      message: _showDetailedErrors
          ? error.toString()
          : 'An unexpected error occurred.',
    );
    res.status(500).header('Content-Type', 'text/html').send(html);
  }

  /// Build HTML error response
  String _buildHtmlErrorResponse(
    Object error,
    StackTrace? stackTrace, {
    int statusCode = 500,
    String title = 'Error',
    String message = 'An error occurred',
  }) {
    final buffer = StringBuffer();
    buffer.write('<!DOCTYPE html>');
    buffer.write('<html><head>');
    buffer.write('<title>$title ($statusCode)</title>');
    buffer.write('<style>');
    buffer.write(
      'body{font-family:system-ui,-apple-system,sans-serif;margin:0;padding:40px;background:#f8f9fa;color:#212529;}',
    );
    buffer.write(
      '.container{max-width:800px;margin:0 auto;background:white;padding:40px;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);}',
    );
    buffer.write('h1{color:#dc3545;margin-top:0;}');
    buffer.write('.message{font-size:1.2em;margin-bottom:20px;}');
    buffer.write(
      '.details{background:#f1f3f5;padding:15px;border-radius:4px;overflow-x:auto;font-family:monospace;font-size:0.9em;}',
    );
    buffer.write(
      '.stack-trace{margin-top:20px;border-top:1px solid #dee2e6;padding-top:20px;}',
    );
    buffer.write('</style>');
    buffer.write('</head><body>');
    buffer.write('<div class="container">');
    buffer.write('<h1>$title</h1>');
    buffer.write('<div class="message">$message</div>');

    if (_showDetailedErrors && error is AppException && error.details != null) {
      buffer.write('<h3>Details</h3>');
      buffer.write(
        '<div class="details">${_escapeHtml(error.details.toString())}</div>',
      );
    }

    if (_showDetailedErrors &&
        _includeStackTracesInResponse &&
        stackTrace != null) {
      buffer.write('<div class="stack-trace">');
      buffer.write('<h3>Stack Trace</h3>');
      buffer.write(
        '<div class="details">${_escapeHtml(stackTrace.toString())}</div>',
      );
      buffer.write('</div>');
    }

    buffer.write(
      '<p><small>Timestamp: ${DateTime.now().toIso8601String()}</small></p>',
    );
    buffer.write('</div>');
    buffer.write('</body></html>');

    return buffer.toString();
  }

  /// Build request context for error reporting
  Map<String, dynamic> _buildRequestContext() {
    final context = <String, dynamic>{};

    try {
      final request = RequestContext.request;
      context['request'] = {
        'method': request.method,
        'url': request.uri.toString(),
        'headers': request.headers,
        'user_agent': request.headers.get('user-agent'),
      };
    } catch (e) {
      // Request context not available
    }

    return context;
  }

  /// Escape HTML special characters
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
