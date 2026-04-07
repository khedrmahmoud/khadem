import '../../application/khadem.dart';
import '../../contracts/http/middleware_contract.dart';

class LoggingMiddleware implements Middleware {
  static const Set<String> _sensitiveKeys = {
    'authorization',
    'password',
    'passwd',
    'pwd',
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'apikey',
    'secret',
    'client_secret',
  };

  static const String _redactedValue = '[REDACTED]';

  @override
  MiddlewareHandler get handler => (req, res, next) async {
    final stopwatch = Stopwatch()..start();
    final sanitizedUri = sanitizeUriForLogging(req.uri);
    Khadem.logger.debug('➡️\tRequest: ${req.method} $sanitizedUri');

    try {
      await next();
    } finally {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      Khadem.logger.debug(
        '⬅️ Response: ${res.statusCode} for ${req.method} $sanitizedUri - ${duration}ms',
      );
    }
  };

  @override
  String get name => "Logger";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;

  static String sanitizeUriForLogging(Uri uri) {
    if (uri.queryParametersAll.isEmpty) {
      return uri.toString();
    }

    final sanitizedPairs = <String>[];
    uri.queryParametersAll.forEach((key, values) {
      final isSensitive = _isSensitiveKey(key);
      final sourceValues = values.isEmpty ? const [''] : values;

      for (final value in sourceValues) {
        final safeValue = isSensitive ? _redactedValue : value;
        sanitizedPairs.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(safeValue)}',
        );
      }
    });

    final sanitizedQuery = sanitizedPairs.join('&');
    return uri.replace(query: sanitizedQuery).toString();
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return _sensitiveKeys.any(
      (sensitive) =>
          normalized == sensitive ||
          normalized.contains(sensitive) ||
          sensitive.contains(normalized),
    );
  }
}
