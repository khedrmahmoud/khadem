import 'package:khadem/src/contracts/http/middleware_contract.dart';
import 'package:khadem/khadem_dart.dart' show Khadem;

class CorsMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        final config = Khadem.config;

        final allowedOrigins = config.get<List>('cors.allowed_origins') ?? [];
        final origin = req.headers['Origin'] as String? ?? '*';

        res
            .header(
              'Access-Control-Allow-Origin',
              (allowedOrigins.contains(origin)) ? origin : 'null',
            )
            .header(
                'Access-Control-Allow-Methods',
                config.get<String>(
                    'cors.allowed_methods', 'GET, POST, PUT, DELETE, OPTIONS')!)
            .header(
                'Access-Control-Allow-Headers',
                config.get<String>(
                    'cors.allowed_headers', 'Content-Type, Authorization')!)
            .header('Access-Control-Allow-Credentials', 'true');

        if (req.method == 'OPTIONS') {
          return res.status(204).header('Content-Length', '0').send('');
        }

        await next();
      };

  @override
  String get name => 'CORS';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
