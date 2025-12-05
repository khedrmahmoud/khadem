import '../../contracts/exceptions/app_exception.dart';
import '../http/context/request_context.dart';
import '../http/context/response_context.dart';
import '../http/response/response.dart';
import 'exception_reporter.dart';

/// Handles exceptions raised in the application and sends appropriate responses.
///
/// This class provides comprehensive exception handling with:
/// - Automatic JSON response formatting
/// - Request context inclusion in error reports
/// - Development vs production error detail levels
/// - Custom error response formatting
/// - Support for different content types
///
/// The handler automatically detects the response format and sends
/// appropriate error responses based on the request's Accept header.
class ExceptionHandler {
  /// Whether to show detailed error information in development
  static bool _showDetailedErrors = true;

  /// Whether to include stack traces in development responses
  static bool _includeStackTracesInResponse = false;

  /// Custom error response formatter
  static Map<String, dynamic> Function(AppException)? _customFormatter;

  /// Configure exception handling settings
  static void configure({
    bool showDetailedErrors = true,
    bool includeStackTracesInResponse = false,
    Map<String, dynamic> Function(AppException)? customFormatter,
  }) {
    _showDetailedErrors = showDetailedErrors;
    _includeStackTracesInResponse = includeStackTracesInResponse;
    _customFormatter = customFormatter;
  }

  /// Handle an exception and send appropriate response
  static void handle(
    Response? response,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final res = response ?? ResponseContext.response;

    // Build context for reporting
    final context = _buildRequestContext();

    if (error is AppException) {
      ExceptionReporter.reportAppException(error, stackTrace, context);
      _sendAppExceptionResponse(res, error, stackTrace);
    } else {
      ExceptionReporter.reportException(error, stackTrace, context);
      _sendGenericExceptionResponse(res, error, stackTrace);
    }
  }

  /// Handle exception with custom response format
  static void handleWithFormat(
    Response? response,
    Object error,
    String format, [
    StackTrace? stackTrace,
  ]) {
    final res = response ?? ResponseContext.response;
    final context = _buildRequestContext();

    if (error is AppException) {
      ExceptionReporter.reportAppException(error, stackTrace, context);
      _sendFormattedAppExceptionResponse(res, error, format, stackTrace);
    } else {
      ExceptionReporter.reportException(error, stackTrace, context);
      _sendFormattedGenericExceptionResponse(res, error, format, stackTrace);
    }
  }

  /// Send response for AppException
  static void _sendAppExceptionResponse(
    Response res,
    AppException error,
    StackTrace? stackTrace,
  ) {
    final responseData = _customFormatter?.call(error) ??
        _formatAppExceptionResponse(error, stackTrace);

    res.status(error.statusCode).sendJson(responseData);
  }

  /// Send response for generic exception
  static void _sendGenericExceptionResponse(
    Response res,
    Object error,
    StackTrace? stackTrace,
  ) {
    final responseData = _formatGenericExceptionResponse(error, stackTrace);

    res.status(500).sendJson(responseData);
  }

  /// Send formatted response for AppException
  static void _sendFormattedAppExceptionResponse(
    Response res,
    AppException error,
    String format,
    StackTrace? stackTrace,
  ) {
    switch (format.toLowerCase()) {
      case 'json':
        _sendAppExceptionResponse(res, error, stackTrace);
        break;
      case 'xml':
        _sendXmlAppExceptionResponse(res, error, stackTrace);
        break;
      case 'html':
        _sendHtmlAppExceptionResponse(res, error, stackTrace);
        break;
      default:
        _sendAppExceptionResponse(res, error, stackTrace);
    }
  }

  /// Send formatted response for generic exception
  static void _sendFormattedGenericExceptionResponse(
    Response res,
    Object error,
    String format,
    StackTrace? stackTrace,
  ) {
    switch (format.toLowerCase()) {
      case 'json':
        _sendGenericExceptionResponse(res, error, stackTrace);
        break;
      case 'xml':
        _sendXmlGenericExceptionResponse(res, error, stackTrace);
        break;
      case 'html':
        _sendHtmlGenericExceptionResponse(res, error, stackTrace);
        break;
      default:
        _sendGenericExceptionResponse(res, error, stackTrace);
    }
  }

  /// Format AppException response
  static Map<String, dynamic> _formatAppExceptionResponse(
    AppException error,
    StackTrace? stackTrace,
  ) {
    final response = <String, dynamic>{
      'error': true,
      'message': error.message,
      'status_code': error.statusCode,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (error.details != null) {
      response['details'] = error.details;
    }

    if (_showDetailedErrors &&
        _includeStackTracesInResponse &&
        stackTrace != null) {
      response['stack_trace'] = stackTrace.toString();
    }

    if (_showDetailedErrors) {
      response['exception_type'] = error.runtimeType.toString();
    }

    return response;
  }

  /// Format generic exception response
  static Map<String, dynamic> _formatGenericExceptionResponse(
    Object error,
    StackTrace? stackTrace,
  ) {
    final response = <String, dynamic>{
      'error': true,
      'message': 'Internal Server Error',
      'status_code': 500,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_showDetailedErrors) {
      response['exception_type'] = error.runtimeType.toString();
      response['exception_message'] = error.toString();
    }

    if (_showDetailedErrors &&
        _includeStackTracesInResponse &&
        stackTrace != null) {
      response['stack_trace'] = stackTrace.toString();
    }

    return response;
  }

  /// Send XML response for AppException
  static void _sendXmlAppExceptionResponse(
    Response res,
    AppException error,
    StackTrace? stackTrace,
  ) {
    final xml = _buildXmlErrorResponse(error, stackTrace);
    res
        .status(error.statusCode)
        .header('Content-Type', 'application/xml')
        .send(xml);
  }

  /// Send XML response for generic exception
  static void _sendXmlGenericExceptionResponse(
    Response res,
    Object error,
    StackTrace? stackTrace,
  ) {
    final xml = _buildXmlErrorResponse(error, stackTrace);
    res.status(500).header('Content-Type', 'application/xml').send(xml);
  }

  /// Send HTML response for AppException
  static void _sendHtmlAppExceptionResponse(
    Response res,
    AppException error,
    StackTrace? stackTrace,
  ) {
    final html = _buildHtmlErrorResponse(error, stackTrace);
    res.status(error.statusCode).header('Content-Type', 'text/html').send(html);
  }

  /// Send HTML response for generic exception
  static void _sendHtmlGenericExceptionResponse(
    Response res,
    Object error,
    StackTrace? stackTrace,
  ) {
    final html = _buildHtmlErrorResponse(error, stackTrace);
    res.status(500).header('Content-Type', 'text/html').send(html);
  }

  /// Build XML error response
  static String _buildXmlErrorResponse(
    Object error,
    StackTrace? stackTrace, [
    int statusCode = 500,
  ]) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.write('<error>');
    buffer.write('<status_code>$statusCode</status_code>');
    buffer.write('<message>');

    if (error is AppException) {
      buffer.write(_escapeXml(error.message));
    } else {
      buffer.write('Internal Server Error');
    }

    buffer.write('</message>');

    if (_showDetailedErrors && error is AppException && error.details != null) {
      buffer.write('<details>');
      buffer.write(_escapeXml(error.details.toString()));
      buffer.write('</details>');
    }

    if (_showDetailedErrors &&
        _includeStackTracesInResponse &&
        stackTrace != null) {
      buffer.write('<stack_trace>');
      buffer.write(_escapeXml(stackTrace.toString()));
      buffer.write('</stack_trace>');
    }

    buffer.write('<timestamp>${DateTime.now().toIso8601String()}</timestamp>');
    buffer.write('</error>');

    return buffer.toString();
  }

  /// Build HTML error response
  static String _buildHtmlErrorResponse(
    Object error,
    StackTrace? stackTrace, [
    int statusCode = 500,
  ]) {
    final buffer = StringBuffer();
    buffer.write('<!DOCTYPE html>');
    buffer.write('<html><head>');
    buffer.write('<title>Error $statusCode</title>');
    buffer.write('<style>');
    buffer.write('body{font-family:Arial,sans-serif;margin:40px;}');
    buffer.write('.error{color:#d32f2f;}');
    buffer.write(
      '.details{background:#f5f5f5;padding:10px;margin:10px 0;border-left:4px solid #d32f2f;}',
    );
    buffer.write('</style>');
    buffer.write('</head><body>');
    buffer.write('<h1 class="error">Error $statusCode</h1>');

    if (error is AppException) {
      buffer.write('<p>${_escapeHtml(error.message)}</p>');
    } else {
      buffer.write('<p>Internal Server Error</p>');
    }

    if (_showDetailedErrors && error is AppException && error.details != null) {
      buffer.write('<div class="details">');
      buffer.write('<strong>Details:</strong><br>');
      buffer.write(_escapeHtml(error.details.toString()));
      buffer.write('</div>');
    }

    if (_showDetailedErrors &&
        _includeStackTracesInResponse &&
        stackTrace != null) {
      buffer.write('<div class="details">');
      buffer.write('<strong>Stack Trace:</strong><br>');
      buffer.write('<pre>${_escapeHtml(stackTrace.toString())}</pre>');
      buffer.write('</div>');
    }

    buffer.write(
      '<p><small>Timestamp: ${DateTime.now().toIso8601String()}</small></p>',
    );
    buffer.write('</body></html>');

    return buffer.toString();
  }

  /// Build request context for error reporting
  static Map<String, dynamic> _buildRequestContext() {
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

  /// Escape XML special characters
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Escape HTML special characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Get current configuration
  static Map<String, dynamic> getConfiguration() {
    return {
      'showDetailedErrors': _showDetailedErrors,
      'includeStackTracesInResponse': _includeStackTracesInResponse,
      'hasCustomFormatter': _customFormatter != null,
    };
  }
}
