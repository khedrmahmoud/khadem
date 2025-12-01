import '../../application/khadem.dart';
import '../../contracts/http/middleware_contract.dart';

class LoggingMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        Khadem.logger.debug('➡️ Request: ${req.method} ${req.uri}');
        await next();
        Khadem.logger.debug('⬅️ Response: ${res.statusCode} for ${req.method} ${req.uri}');
      };

  @override
  String get name => "Logger";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
