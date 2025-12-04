import '../../contracts/http/middleware_contract.dart';

/// Adds common security headers to responses.
class SecurityHeadersMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
        // Prevent MIME type sniffing
        res.header('X-Content-Type-Options', 'nosniff');

        // Prevent clickjacking
        res.header('X-Frame-Options', 'DENY');

        // Enable XSS filtering
        res.header('X-XSS-Protection', '1; mode=block');

        // Enforce HTTPS (HSTS) - 1 year
        // Only effective if served over HTTPS, but good practice to include
        res.header(
            'Strict-Transport-Security', 'max-age=31536000; includeSubDomains',);

        // Referrer Policy
        res.header('Referrer-Policy', 'strict-origin-when-cross-origin');

        await next();
      };

  @override
  String get name => "SecurityHeaders";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
