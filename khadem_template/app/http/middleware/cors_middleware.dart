import 'package:khadem/src/contracts/http/middleware_contract.dart';

class CorsMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        res
            .header('Access-Control-Allow-Origin', '*')
            .header(
                'Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
            .header(
                'Access-Control-Allow-Headers', 'Content-Type, Authorization')
            .header('Access-Control-Allow-Credentials', 'true');

        // ✅ Immediately respond to preflight request
        if (req.method == 'OPTIONS') {
          return res.status(200).send('');
        }

        // For all other requests, continue
        await next();
      };

  @override
  String get name => 'CORS';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
