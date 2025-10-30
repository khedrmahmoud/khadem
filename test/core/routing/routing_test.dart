import 'package:khadem/src/contracts/http/middleware_contract.dart';
import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/core/http/response/index.dart';
import 'package:khadem/src/core/routing/index.dart';
import 'package:test/test.dart';

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
        final middleware =
            Middleware((req, res, next) async => await next(), name: 'auth');
        registry.get('/test', (req, res) async {}, middleware: [middleware]);

        expect(registry.routes.length, equals(1));
        expect(registry.routes.first.middleware.length, equals(1));
        expect(registry.routes.first.middleware.first.name, equals('auth'));
      });

      test('should register ANY method routes', () {
        registry.any('/test', (req, res) async {});
        expect(
          registry.routes.length,
          equals(6),
        ); // GET, POST, PUT, PATCH, DELETE, HEAD

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
        expect(
          registry.routes[0].path,
          equals('/users/profile'),
        ); // Static first
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

    setUp(() {
      registry = RouteRegistry();
    });

    group('Route Matching', () {
      test('should match exact static route', () {
        registry.get('/users', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('GET', '/users');
        expect(result, isNotNull);
        expect(result!.params, isEmpty);
      });

      test('should match dynamic route with parameters', () {
        registry.get('/users/:id', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('GET', '/users/123');
        expect(result, isNotNull);
        expect(result!.params['id'], equals('123'));
      });

      test('should match route with multiple parameters', () {
        registry.get('/users/:userId/posts/:postId', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('GET', '/users/123/posts/456');
        expect(result, isNotNull);
        expect(result!.params['userId'], equals('123'));
        expect(result.params['postId'], equals('456'));
      });

      test('should return null for non-matching route', () {
        registry.get('/users', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('GET', '/posts');
        expect(result, isNull);
      });

      test('should return null for non-matching method', () {
        registry.get('/users', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('POST', '/users');
        expect(result, isNull);
      });

      test('should prioritize static routes over dynamic', () {
        registry.get('/users/profile', (req, res) async {});
        registry.get('/users/:id', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('GET', '/users/profile');
        expect(result, isNotNull);
        expect(result!.params, isEmpty); // Should match static route
      });

      test('should match dynamic route when static not found', () {
        registry.get('/users/profile', (req, res) async {});
        registry.get('/users/:id', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final result = matcher.match('GET', '/users/123');
        expect(result, isNotNull);
        expect(result!.params['id'], equals('123'));
      });
    });

    group('Multiple Matches', () {
      test('should find all matching routes', () {
        registry.any('/test', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);

        final results = matcher.findAllMatches('GET', '/test');
        expect(results.length, equals(1));
        expect(results.first.params, isEmpty);
      });

      test('should return empty list when no matches', () {
        final matcher = RouteMatcher(registry.routes);
        final results = matcher.findAllMatches('GET', '/nonexistent');
        expect(results, isEmpty);
      });
    });

    group('Match Checking', () {
      test('should return true when route exists', () {
        registry.get('/test', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);
        expect(matcher.hasMatch('GET', '/test'), isTrue);
      });

      test('should return false when route does not exist', () {
        final matcher = RouteMatcher(registry.routes);
        expect(matcher.hasMatch('GET', '/nonexistent'), isFalse);
      });

      test('should return false when method does not match', () {
        registry.get('/test', (req, res) async {});
        final matcher = RouteMatcher(registry.routes);
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
        final middleware =
            Middleware((req, res, next) async => await next(), name: 'auth');

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
        final groupMiddleware =
            Middleware((req, res, next) async => await next(), name: 'auth');
        final routeMiddleware = Middleware(
          (req, res, next) async => await next(),
          name: 'rate-limit',
        );

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
        final originalHandler = (Request req, Response res) async {};

        final wrappedHandler =
            handler.wrapWithExceptionHandler(originalHandler);

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

        await handler.executeHandler(
          testHandler,
          FakeRequest(),
          FakeResponse(),
        );
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
        final middleware =
            Middleware((req, res, next) async => await next(), name: 'test');
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
        final middleware =
            Middleware((req, res, next) async => await next(), name: 'auth');

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

  group('Trailing Slash Normalization', () {
    late Router router;
    final handler = (Request req, Response res) async {};

    setUp(() {
      router = Router();
    });

    group('Static Routes', () {
      test('should match path with and without trailing slash', () {
        router.get('/users', handler);

        final match1 = router.match('GET', '/users');
        final match2 = router.match('GET', '/users/');

        expect(match1, isNotNull);
        expect(match2, isNotNull);
      });

      test('should preserve root path', () {
        router.get('/', handler);

        expect(router.match('GET', '/'), isNotNull);
      });

      test('should work with nested paths', () {
        router.get('/api/users/profile', handler);

        expect(router.match('GET', '/api/users/profile'), isNotNull);
        expect(router.match('GET', '/api/users/profile/'), isNotNull);
      });

      test('should work with multiple segments', () {
        router.get('/api/v1/users/list', handler);

        expect(router.match('GET', '/api/v1/users/list'), isNotNull);
        expect(router.match('GET', '/api/v1/users/list/'), isNotNull);
      });
    });

    group('Dynamic Routes', () {
      test('should work with single parameter', () {
        router.get('/users/:id', handler);

        final match1 = router.match('GET', '/users/123');
        final match2 = router.match('GET', '/users/123/');

        expect(match1, isNotNull);
        expect(match2, isNotNull);
        expect(match1!.params['id'], equals('123'));
        expect(match2!.params['id'], equals('123'));
      });

      test('should work with multiple parameters', () {
        router.get('/users/:userId/posts/:postId', handler);

        final match1 = router.match('GET', '/users/123/posts/456');
        final match2 = router.match('GET', '/users/123/posts/456/');

        expect(match1, isNotNull);
        expect(match2, isNotNull);
        expect(match1!.params['userId'], equals('123'));
        expect(match1.params['postId'], equals('456'));
        expect(match2!.params['userId'], equals('123'));
        expect(match2.params['postId'], equals('456'));
      });

      test('should work with mixed static and dynamic segments', () {
        router.get('/api/users/:id/profile', handler);

        final match1 = router.match('GET', '/api/users/123/profile');
        final match2 = router.match('GET', '/api/users/123/profile/');

        expect(match1, isNotNull);
        expect(match2, isNotNull);
        expect(match1!.params['id'], equals('123'));
        expect(match2!.params['id'], equals('123'));
      });
    });

    group('Route Groups', () {
      test('should normalize paths in route groups', () {
        router.group(
          prefix: '/api',
          routes: (r) {
            r.get('/users', handler);
            r.get('/posts/:id', handler);
          },
        );

        expect(router.match('GET', '/api/users'), isNotNull);
        expect(router.match('GET', '/api/users/'), isNotNull);
        expect(router.match('GET', '/api/posts/123'), isNotNull);
        expect(router.match('GET', '/api/posts/123/'), isNotNull);
      });
    });

    group('HTTP Methods', () {
      test('should work across all HTTP methods', () {
        router.get('/users', handler);
        router.post('/users', handler);
        router.put('/users/:id', handler);
        router.delete('/users/:id', handler);

        expect(router.match('GET', '/users/'), isNotNull);
        expect(router.match('POST', '/users/'), isNotNull);
        expect(router.match('PUT', '/users/123/'), isNotNull);
        expect(router.match('DELETE', '/users/123/'), isNotNull);
      });
    });
  });

  group('Performance Optimization', () {
    late Router router;
    final handler = (Request req, Response res) async {};

    setUp(() {
      router = Router();
    });

    test('should handle large number of static routes efficiently', () {
      // Register 100 static routes
      for (int i = 0; i < 100; i++) {
        router.get('/route$i', handler);
      }

      final stopwatch = Stopwatch()..start();
      final match = router.match('GET', '/route99');
      stopwatch.stop();

      expect(match, isNotNull);
      // Should be very fast (< 10ms even on slow machines)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('should separate static and dynamic routes', () {
      // Register mix of static and dynamic routes
      router.get('/static1', handler);
      router.get('/static2', handler);
      router.get('/users/:id', handler);
      router.get('/posts/:id', handler);

      // Static routes should match faster than dynamic
      final staticStopwatch = Stopwatch()..start();
      router.match('GET', '/static1');
      staticStopwatch.stop();

      final dynamicStopwatch = Stopwatch()..start();
      router.match('GET', '/users/123');
      dynamicStopwatch.stop();

      expect(router.match('GET', '/static1'), isNotNull);
      expect(router.match('GET', '/users/123'), isNotNull);
      // Both should be fast, but static should be faster or equal
      expect(
        staticStopwatch.elapsedMicroseconds,
        lessThanOrEqualTo(dynamicStopwatch.elapsedMicroseconds + 1000),
      );
    });

    test('should handle mix of trailing slash and no trailing slash', () {
      // Register 50 routes
      for (int i = 0; i < 50; i++) {
        router.get('/api/resource$i', handler);
      }

      // Match with and without trailing slashes
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 50; i++) {
        router.match('GET', '/api/resource$i');
        router.match('GET', '/api/resource$i/');
      }
      stopwatch.stop();

      // 100 matches should be very fast
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
