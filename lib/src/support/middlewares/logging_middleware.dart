import '../../application/khadem.dart';
import '../../contracts/http/middleware_contract.dart';

class LoggingMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        final stopwatch = Stopwatch()..start();
        Khadem.logger.debug('➡️ Request: ${req.method} ${req.uri}');
        
        try {
          await next();
        } finally {
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          Khadem.logger.debug(
            '⬅️ Response: ${res.statusCode} for ${req.method} ${req.uri} - ${duration}ms',
          );
        }
      };

  @override
  String get name => "Logger";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
