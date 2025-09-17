
import 'package:test/test.dart';

import '../../../lib/src/contracts/http/middleware_contract.dart';
import '../../../lib/src/core/http/request/request.dart';
import '../../../lib/src/core/http/response/index.dart';
import '../../../lib/src/core/routing/index.dart';
import '../../mocks/http_mocks.dart';


void main() {
  group('RouteRegistry', () {
    late RouteRegistry registry;

    setUp(() {
      registry = RouteRegistry();
    });

    tearDown(() {
      registry.clear();
    });

    group('Route Registration', () {
      test('should register route with basic parameters', () {
        registry.register('GET', '/test', (req, res) async {}, []);
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('GET'));
        expect(registry.routes.first.path, equals('/test'));
      });

      test('should register GET route', () {
        registry.get('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('GET'));
        expect(registry.routes.first.path, equals('/test'));
      });

      test('should register POST route', () {
        registry.post('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('POST'));
      });

      test('should register PUT route', () {
        registry.put('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('PUT'));
      });

      test('should register PATCH route', () {
        registry.patch('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('PATCH'));
      });

      test('should register DELETE route', () {
        registry.delete('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('DELETE'));
      });

      test('should register HEAD route', () {
        registry.head('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('HEAD'));
      });

      test('should register OPTIONS route', () {
        registry.options('/test', (req, res) async {});
        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.method, equals('OPTIONS'));
      });

      test('should register route with middleware', () {
        final middleware = Middleware((req, res, next) async => await next(), name: 'auth');
        registry.get('/test', (req, res) async {}, middleware: [middleware]);

        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.middleware.length, equals(1));
        expect(registry.routes.first.middleware.first.name, equals('auth'));
      });

      test('should register ANY method routes', () {
        registry.any('/test', (req, res) async {});
        expect(registry.routes.length, equals(6)); // GET, POST, PUT, PATCH, DELETE, HEAD

        final methods = registry.routes.map((r) => r.method).toSet();
        expect(methods, contains('GET'));
        expect(methods, contains('POST'));
        expect(methods, contains('PUT'));
        expect(methods, contains('PATCH'));
        expect(methods, contains('DELETE'));
        expect(methods, contains('HEAD'));
      });

      test('should prioritize static routes over dynamic routes', () {
        registry.get('/users/profile', (req, res) async {});
        registry.get('/users/:id', (req, res) async {});

        expect(registry.routes.length, equals(2));
        expect(registry.routes[0].path, equals('/users/profile')); // Static first
        expect(registry.routes[1].path, equals('/users/:id')); // Dynamic second
      });
    });

    group('Route Clearing', () {
      test('should clear all routes', () {
        registry.get('/test1', (req, res) async {});
        registry.post('/test2', (req, res) async {});
        expect(registry.routes.length, equals(2));

        registry.clear();
        expect(registry.routes.length, equals(0));
      });
    });
  });

  group('RouteMatcher', () {
    late RouteRegistry registry;
    late RouteMatcher matcher;

    setUp(() {
      registry = RouteRegistry();
      matcher = RouteMatcher(registry.routes);
    });

    group('Route Matching', () {
      test('should match exact static route', () {
        registry.get('/users', (req, res) async {});

        final result = matcher.match('GET', '/users');
        expect(result, isNotNull);
        expect(result!.params, isEmpty);
      });

      test('should match dynamic route with parameters', () {
        registry.get('/users/:id', (req, res) async {});

        final result = matcher.match('GET', '/users/123');
        expect(result, isNotNull);
        expect(result!.params['id'], equals('123'));
      });

      test('should match route with multiple parameters', () {
        registry.get('/users/:userId/posts/:postId', (req, res) async {});

        final result = matcher.match('GET', '/users/123/posts/456');
        expect(result, isNotNull);
        expect(result!.params['userId'], equals('123'));
        expect(result.params['postId'], equals('456'));
      });

      test('should return null for non-matching route', () {
        registry.get('/users', (req, res) async {});

        final result = matcher.match('GET', '/posts');
        expect(result, isNull);
      });

      test('should return null for non-matching method', () {
        registry.get('/users', (req, res) async {});

        final result = matcher.match('POST', '/users');
        expect(result, isNull);
      });

      test('should prioritize static routes over dynamic', () {
        registry.get('/users/profile', (req, res) async {});
        registry.get('/users/:id', (req, res) async {});

        final result = matcher.match('GET', '/users/profile');
        expect(result, isNotNull);
        expect(result!.params, isEmpty); // Should match static route
      });

      test('should match dynamic route when static not found', () {
        registry.get('/users/profile', (req, res) async {});
        registry.get('/users/:id', (req, res) async {});

        final result = matcher.match('GET', '/users/123');
        expect(result, isNotNull);
        expect(result!.params['id'], equals('123'));
      });
    });

    group('Multiple Matches', () {
      test('should find all matching routes', () {
        registry.any('/test', (req, res) async {});

        final results = matcher.findAllMatches('GET', '/test');
        expect(results.length, equals(1));
        expect(results.first.params, isEmpty);
      });

      test('should return empty list when no matches', () {
        final results = matcher.findAllMatches('GET', '/nonexistent');
        expect(results, isEmpty);
      });
    });

    group('Match Checking', () {
      test('should return true when route exists', () {
        registry.get('/test', (req, res) async {});
        expect(matcher.hasMatch('GET', '/test'), isTrue);
      });

      test('should return false when route does not exist', () {
        expect(matcher.hasMatch('GET', '/nonexistent'), isFalse);
      });

      test('should return false when method does not match', () {
        registry.get('/test', (req, res) async {});
        expect(matcher.hasMatch('POST', '/test'), isFalse);
      });
    });
  });

  group('RouteGroupManager', () {
    late RouteRegistry registry;
    late RouteGroupManager groupManager;

    setUp(() {
      registry = RouteRegistry();
      groupManager = RouteGroupManager(registry);
    });

    group('Route Grouping', () {
      test('should group routes with prefix', () {
        groupManager.group(
          prefix: '/api',
          routes: (r) {
            r.get('/users', (req, res) async {});
            r.post('/users', (req, res) async {});
          },
        );

        expect(registry.routes.length, equals(2));
        expect(registry.routes[0].path, equals('/api/users'));
        expect(registry.routes[1].path, equals('/api/users'));
        expect(registry.routes[0].method, equals('GET'));
        expect(registry.routes[1].method, equals('POST'));
      });

      test('should group routes with middleware', () {
        final middleware = Middleware((req, res, next) async => await next(), name: 'auth');

        groupManager.group(
          prefix: '/api',
          middleware: [middleware],
          routes: (r) {
            r.get('/users', (req, res) async {});
          },
        );

        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.middleware.length, equals(1));
        expect(registry.routes.first.middleware.first.name, equals('auth'));
      });

      test('should combine group middleware with route middleware', () {
        final groupMiddleware = Middleware((req, res, next) async => await next(), name: 'auth');
        final routeMiddleware = Middleware((req, res, next) async => await next(), name: 'rate-limit');

        groupManager.group(
          prefix: '/api',
          middleware: [groupMiddleware],
          routes: (r) {
            r.get('/users', (req, res) async {}, middleware: [routeMiddleware]);
          },
        );

        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.middleware.length, equals(2));
        expect(registry.routes.first.middleware[0].name, equals('auth'));
        expect(registry.routes.first.middleware[1].name, equals('rate-limit'));
      });

      test('should handle nested prefixes correctly', () {
        groupManager.group(
          prefix: '/api/v1',
          routes: (r) {
            r.get('/users', (req, res) async {});
          },
        );

        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.path, equals('/api/v1/users'));
      });

      test('should handle empty prefix', () {
        groupManager.group(
          prefix: '',
          routes: (r) {
            r.get('/users', (req, res) async {});
          },
        );

        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.path, equals('/users'));
      });
    });
  });

  group('RouteHandler', () {
    late RouteHandler handler;

    setUp(() {
      handler = RouteHandler();
    });

    group('Handler Wrapping', () {
      test('should wrap handler with exception handling', () {
        var executed = false;
        final originalHandler = (Request req, Response res) async {
          executed = true;
        };

        final wrappedHandler = handler.wrapWithExceptionHandler(originalHandler);

        // Note: We can't easily test the exception handling without mocking
        // the ExceptionHandler, but we can verify the wrapper is created
        expect(wrappedHandler, isNotNull);
      });

      test('should wrap multiple handlers', () {
        final handlers = [
          (Request req, Response res) async {},
          (Request req, Response res) async {},
        ];

        final wrappedHandlers = handler.wrapHandlers(handlers);
        expect(wrappedHandlers.length, equals(2));
      });
    });

    group('Handler Execution', () {
      test('should execute handler successfully', () async {
        var executed = false;
        final testHandler = (Request req, Response res) async {
          executed = true;
        };

        await handler.executeHandler(testHandler, FakeRequest(), FakeResponse());
        expect(executed, isTrue);
      });
    });
  });

  group('Router Integration', () {
    late Router router;

    setUp(() {
      router = Router();
    });

    group('Route Registration', () {
      test('should register routes through main router', () {
        router.get('/test', (req, res) async {});
        expect(router.routes.length, equals(1));
        expect(router.routes.first.method, equals('GET'));
        expect(router.routes.first.path, equals('/test'));
      });

      test('should register routes with middleware', () {
        final middleware = Middleware((req, res, next) async => await next(), name: 'test');
        router.get('/test', (req, res) async {}, middleware: [middleware]);

        expect(router.routes.length, equals(1));
        expect(router.routes.first.middleware.length, equals(1));
      });
    });

    group('Route Matching', () {
      test('should match registered routes', () {
        router.get('/users/:id', (req, res) async {});

        final result = router.match('GET', '/users/123');
        expect(result, isNotNull);
        expect(result!.params['id'], equals('123'));
      });

      test('should return null for unmatched routes', () {
        final result = router.match('GET', '/nonexistent');
        expect(result, isNull);
      });
    });

    group('Route Grouping', () {
      test('should group routes with prefix', () {
        router.group(
          prefix: '/api',
          routes: (r) {
            r.get('/users', (req, res) async {});
            r.post('/posts', (req, res) async {});
          },
        );

        expect(router.routes.length, equals(2));
        expect(router.routes[0].path, equals('/api/users'));
        expect(router.routes[1].path, equals('/api/posts'));
      });

      test('should group routes with middleware', () {
        final middleware = Middleware((req, res, next) async => await next(), name: 'auth');

        router.group(
          prefix: '/api',
          middleware: [middleware],
          routes: (r) {
            r.get('/users', (req, res) async {});
          },
        );

        expect(router.routes.length, equals(1));
        expect(router.routes.first.middleware.length, equals(1));
        expect(router.routes.first.middleware.first.name, equals('auth'));
      });
    });

    group('Route Clearing', () {
      test('should clear all routes', () {
        router.get('/test1', (req, res) async {});
        router.post('/test2', (req, res) async {});
        expect(router.routes.length, equals(2));

        router.clear();
        expect(router.routes.length, equals(0));
      });
    });

    group('HTTP Methods', () {
      test('should support all HTTP methods', () {
        router.get('/test', (req, res) async {});
        router.post('/test', (req, res) async {});
        router.put('/test', (req, res) async {});
        router.patch('/test', (req, res) async {});
        router.delete('/test', (req, res) async {});
        router.head('/test', (req, res) async {});
        router.options('/test', (req, res) async {});

        expect(router.routes.length, equals(7));
        final methods = router.routes.map((r) => r.method).toSet();
        expect(methods, contains('GET'));
        expect(methods, contains('POST'));
        expect(methods, contains('PUT'));
        expect(methods, contains('PATCH'));
        expect(methods, contains('DELETE'));
        expect(methods, contains('HEAD'));
        expect(methods, contains('OPTIONS'));
      });

      test('should support ANY method registration', () {
        router.any('/test', (req, res) async {});
        expect(router.routes.length, equals(6)); // Excludes OPTIONS for ANY

        final methods = router.routes.map((r) => r.method).toSet();
        expect(methods, contains('GET'));
        expect(methods, contains('POST'));
        expect(methods, contains('PUT'));
        expect(methods, contains('PATCH'));
        expect(methods, contains('DELETE'));
        expect(methods, contains('HEAD'));
      });
    });
  });
}
