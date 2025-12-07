import 'dart:io';

import '../../application/khadem.dart';
import '../../contracts/exceptions/app_exception.dart';
import '../http/context/request_context.dart';

/// Central place to log or report exceptions to a third-party service.
///
/// This class provides a comprehensive exception reporting system that can:
/// - Log exceptions with contextual information
/// - Report to external services (Sentry, Rollbar, etc.)
/// - Include user, request, and environment context
/// - Support different reporting levels and filtering
///
/// The default implementation logs to the application logger, but can be
/// extended to integrate with third-party error tracking services.
class ExceptionReporter {
  /// Whether to include detailed stack traces in reports
  static bool _includeStackTraces = true;

  /// Whether to include user context in reports
  static bool _includeUserContext = true;

  /// Whether to include request context in reports
  static bool _includeRequestContext = true;

  /// Whether to include environment information
  static bool _includeEnvironmentInfo = true;

  /// Minimum log level for reporting exceptions
  static String _minimumReportLevel = 'error';

  /// Custom context data to include in all reports
  static Map<String, dynamic> _globalContext = {};

  /// Configure exception reporting settings
  static void configure({
    bool includeStackTraces = true,
    bool includeUserContext = true,
    bool includeRequestContext = true,
    bool includeEnvironmentInfo = true,
    String minimumReportLevel = 'error',
    Map<String, dynamic>? globalContext,
  }) {
    _includeStackTraces = includeStackTraces;
    _includeUserContext = includeUserContext;
    _includeRequestContext = includeRequestContext;
    _includeEnvironmentInfo = includeEnvironmentInfo;
    _minimumReportLevel = minimumReportLevel;
    if (globalContext != null) {
      _globalContext = Map.from(globalContext);
    }
  }

  /// Report an application-specific exception with full context
  static void reportAppException(
    AppException error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  ]) {
    final context = _buildExceptionContext(
      error: error,
      stackTrace: stackTrace,
      additionalContext: additionalContext,
    );

    final logMessage = _formatExceptionMessage(error, context);

    // Log based on severity
    if (error.statusCode >= 500) {
      Khadem.logger
          .critical(logMessage, context: context, stackTrace: stackTrace);
    } else if (error.statusCode >= 400) {
      Khadem.logger
          .warning(logMessage, context: context, stackTrace: stackTrace);
    } else {
      Khadem.logger.error(logMessage, context: context, stackTrace: stackTrace);
    }

    // Send to external service if configured
    _sendToExternalService(error, context, stackTrace);
  }

  /// Report a generic exception with full context
  static void reportException(
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  ]) {
    final context = _buildExceptionContext(
      error: error,
      stackTrace: stackTrace,
      additionalContext: additionalContext,
    );

    final logMessage = _formatExceptionMessage(error, context);

    Khadem.logger.error(logMessage, context: context, stackTrace: stackTrace);

    // Send to external service if configured
    _sendToExternalService(error, context, stackTrace);
  }

  /// Report an exception with custom severity level
  static void reportWithLevel(
    String level,
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  ]) {
    final context = _buildExceptionContext(
      error: error,
      stackTrace: stackTrace,
      additionalContext: additionalContext,
    );

    final logMessage = _formatExceptionMessage(error, context);

    switch (level.toLowerCase()) {
      case 'critical':
        Khadem.logger
            .critical(logMessage, context: context, stackTrace: stackTrace);
        break;
      case 'error':
        Khadem.logger
            .error(logMessage, context: context, stackTrace: stackTrace);
        break;
      case 'warning':
        Khadem.logger
            .warning(logMessage, context: context, stackTrace: stackTrace);
        break;
      case 'info':
        Khadem.logger
            .info(logMessage, context: context, stackTrace: stackTrace);
        break;
      case 'debug':
        Khadem.logger
            .debug(logMessage, context: context, stackTrace: stackTrace);
        break;
      default:
        Khadem.logger
            .error(logMessage, context: context, stackTrace: stackTrace);
    }

    // Send to external service if configured
    _sendToExternalService(error, context, stackTrace);
  }

  /// Build comprehensive context for exception reporting
  static Map<String, dynamic> _buildExceptionContext({
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) {
    final context = <String, dynamic>{};

    // Add global context
    context.addAll(_globalContext);

    // Add additional context
    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    // Add exception details
    context['exception'] = {
      'type': error.runtimeType.toString(),
      'message': error.toString(),
    };

    // Add stack trace if enabled
    if (_includeStackTraces && stackTrace != null) {
      context['stack_trace'] = stackTrace.toString();
    }

    // Add timestamp
    context['timestamp'] = DateTime.now().toIso8601String();

    // Add environment info if enabled
    if (_includeEnvironmentInfo) {
      context['environment'] = {
        'platform': Platform.operatingSystem,
        'version': Platform.version,
        'locale': Platform.localeName,
        'executable': Platform.executable,
        'script': Platform.script.toString(),
      };
    }

    // Add request context if enabled
    if (_includeRequestContext && !context.containsKey('request')) {
      // Try to get request context if available
      try {
        if (RequestContext.hasRequest) {
          final request = RequestContext.request;
          context['request'] = {
            'method': request.method,
            'url': request.uri.toString(),
            'headers': request.headers.toMap(),
            'user_agent': request.headers.get('user-agent'),
            'ip': request.ip,
          };
        } else {
          context['request'] = {
            'method': null,
            'url': null,
            'headers': null,
            'user_agent': null,
          };
        }
      } catch (e) {
        context['request'] = {
          'method': null,
          'url': null,
          'headers': null,
          'user_agent': null,
          'error': 'Failed to retrieve request context: $e',
        };
      }
    }

    // Add user context if enabled
    if (_includeUserContext && !context.containsKey('user')) {
      try {
        if (RequestContext.hasRequest && RequestContext.isAuthenticated) {
           context['user'] = {
            'id': RequestContext.userId,
            'ip': RequestContext.request.ip,
          };
        } else {
           context['user'] = {
            'id': null,
            'ip': null,
          };
        }
      } catch (_) {
         context['user'] = {
            'id': null,
            'ip': null,
          };
      }
    }

    return context;
  }

  /// Format exception message for logging
  static String _formatExceptionMessage(
    Object error,
    Map<String, dynamic> context,
  ) {
    final buffer = StringBuffer();

    buffer.write('Exception: ${error.runtimeType}');

    if (error is AppException) {
      buffer.write(' (Status: ${error.statusCode})');
    }

    buffer.write(' - ${error.toString()}');

    // Add context summary
    final request = context['request'];
    if (request != null &&
        request['method'] != null &&
        request['url'] != null) {
      buffer.write(' [${request['method']} ${request['url']}]');
    }

    final user = context['user'];
    if (user != null && user['id'] != null) {
      buffer.write(' [User: ${user['id']}]');
    }

    return buffer.toString();
  }

  /// Send exception to external service (placeholder for integration)
  static void _sendToExternalService(
    Object error,
    Map<String, dynamic> context,
    StackTrace? stackTrace,
  ) {
    // Placeholder for external service integration
    // This could be extended to send to Sentry, Rollbar, Bugsnag, etc.

    // Example:
    // if (_externalServiceConfigured) {
    //   _externalService.report(error, context: context, stackTrace: stackTrace);
    // }
  }

  /// Add custom context that will be included in all future reports
  static void addGlobalContext(String key, dynamic value) {
    _globalContext[key] = value;
  }

  /// Remove custom context
  static void removeGlobalContext(String key) {
    _globalContext.remove(key);
  }

  /// Clear all custom context
  static void clearGlobalContext() {
    _globalContext.clear();
  }

  /// Get current configuration
  static Map<String, dynamic> getConfiguration() {
    return {
      'includeStackTraces': _includeStackTraces,
      'includeUserContext': _includeUserContext,
      'includeRequestContext': _includeRequestContext,
      'includeEnvironmentInfo': _includeEnvironmentInfo,
      'minimumReportLevel': _minimumReportLevel,
      'globalContext': Map.from(_globalContext),
    };
  }
}
