import '../../contracts/http/middleware_contract.dart';
import '../../application/khadem.dart';

class LoggingMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        final start = DateTime.now();
        Khadem.logger.debug('➡️ Request: ${req.method} ${req.uri}');
        await next();
        final duration = DateTime.now().difference(start);
        Khadem.logger.debug(
            '⬅️ Response: ${res.raw.response.statusCode} in ${duration.inMilliseconds}ms');
      };

  @override
  String get name => "Logger";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
