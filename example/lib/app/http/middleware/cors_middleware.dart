import 'package:khadem/khadem.dart'
    show Khadem, Middleware, MiddlewarePriority, MiddlewareHandler;

class CorsMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        final config = Khadem.config;

        final allowedOrigins = config.get<List>('cors.allowed_origins') ?? [];
        final origin = req.headers.header('origin') ?? '*';

        res.cors(
          allowOrigin: (allowedOrigins.contains(origin)) ? origin : 'null',
          allowMethods: config.get<String>(
            'cors.allowed_methods',
            'GET, POST, PUT, DELETE, OPTIONS',
          ),
          allowHeaders: config.get<String>(
            'cors.allowed_headers',
            'Content-Type, Authorization',
          ),
          allowCredentials: true,
        );

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
