import '../../contracts/http/middleware_contract.dart';

/// Handles Cross-Origin Resource Sharing (CORS) headers.
class CorsMiddleware implements Middleware {
  final String allowOrigin;
  final String allowMethods;
  final String allowHeaders;
  final String? exposeHeaders;
  final bool allowCredentials;
  final int? maxAge;

  CorsMiddleware({
    this.allowOrigin = '*',
    this.allowMethods = 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    this.allowHeaders = 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
    this.exposeHeaders,
    this.allowCredentials = false,
    this.maxAge = 86400, // 24 hours
  });

  @override
  MiddlewareHandler get handler => (req, res, next) async {
        // Set CORS headers
        res.header('Access-Control-Allow-Origin', allowOrigin);
        res.header('Access-Control-Allow-Methods', allowMethods);
        res.header('Access-Control-Allow-Headers', allowHeaders);
        
        if (exposeHeaders != null) {
          res.header('Access-Control-Expose-Headers', exposeHeaders!);
        }

        if (allowCredentials) {
          res.header('Access-Control-Allow-Credentials', 'true');
        }

        if (maxAge != null) {
          res.header('Access-Control-Max-Age', maxAge.toString());
        }

        // Handle preflight requests
        if (req.method == 'OPTIONS') {
          res.status(204).empty();
          return;
        }

        await next();
      };

  @override
  String get name => "Cors";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
