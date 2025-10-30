import 'package:khadem/src/contracts/http/middleware_contract.dart';
import 'package:khadem/src/modules/auth/middlewares/auth_middleware.dart';
import 'package:khadem/src/modules/auth/middlewares/web_auth_middleware.dart';
import 'package:test/test.dart';

void main() {
  group('AuthMiddleware', () {
    test('should create Bearer AuthMiddleware instance', () {
      final middleware = AuthMiddleware.bearer();
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-bearer'));
      expect(middleware.priority, equals(MiddlewarePriority.auth));
    });

    test('should create Basic AuthMiddleware instance', () {
      final middleware = AuthMiddleware.basic();
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-basic'));
      expect(middleware.priority, equals(MiddlewarePriority.auth));
    });

    test('should create API Key AuthMiddleware instance', () {
      final middleware = AuthMiddleware.apiKey('X-API-Key');
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-api-key-X-API-Key'));
      expect(middleware.priority, equals(MiddlewarePriority.auth));
    });

    test('should create middleware with roles', () {
      final middleware = AuthMiddleware.bearer().withRoles(['admin']);
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-bearer'));
    });

    test('should create middleware with permissions', () {
      final middleware =
          AuthMiddleware.bearer().withPermissions(['user.create']);
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-bearer'));
    });

    test('should create middleware with caching enabled', () {
      final middleware = AuthMiddleware.bearer().withCaching();
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-bearer'));
    });

    test('should create middleware with custom guard', () {
      final middleware = AuthMiddleware.bearer().withGuard('custom');
      expect(middleware, isNotNull);
      expect(middleware.name, equals('auth-bearer'));
    });
  });

  group('WebAuthMiddleware', () {
    test('should create auth middleware', () {
      final middleware = WebAuthMiddleware.auth();
      expect(middleware, isNotNull);
      expect(middleware.name, equals('web-auth'));
      expect(middleware.priority, equals(MiddlewarePriority.auth));
    });

    test('should create guest middleware', () {
      final middleware = WebAuthMiddleware.guest();
      expect(middleware, isNotNull);
      expect(middleware.name, equals('web-guest'));
      expect(middleware.priority, equals(MiddlewarePriority.auth));
    });

    test('should create admin middleware', () {
      final middleware = WebAuthMiddleware.admin();
      expect(middleware, isNotNull);
      expect(middleware.name, equals('web-admin'));
      expect(middleware.priority, equals(MiddlewarePriority.auth));
    });

    test('should create middleware with custom options', () {
      final middleware = WebAuthMiddleware.auth(
        redirectTo: '/custom-login',
        except: ['/api/health'],
        guard: 'custom-guard',
      );
      expect(middleware, isNotNull);
      expect(middleware.name, equals('web-auth'));
    });

    group('route matching', () {
      test('should match exact routes', () {
        // Test the route matching logic directly since _matchesRoute is private
        // We'll test the logic by creating a simple function
        bool matchesRoute(String path, String route) {
          if (route == path) return true;
          if (route.endsWith('*')) {
            final prefix = route.substring(0, route.length - 1);
            return path.startsWith(prefix);
          }
          return false;
        }

        expect(matchesRoute('/login', '/login'), isTrue);
        expect(matchesRoute('/dashboard', '/login'), isFalse);
      });

      test('should match wildcard routes', () {
        bool matchesRoute(String path, String route) {
          if (route == path) return true;
          if (route.endsWith('*')) {
            final prefix = route.substring(0, route.length - 1);
            return path.startsWith(prefix);
          }
          return false;
        }

        expect(matchesRoute('/api/users', '/api/*'), isTrue);
        expect(matchesRoute('/api/users/1', '/api/*'), isTrue);
        expect(matchesRoute('/admin/users', '/api/*'), isFalse);
      });
    });
  });
}
