import 'package:khadem/src/contracts/http/middleware_contract.dart';
import 'package:khadem/src/support/middlewares/cache_middleware.dart';
import 'package:test/test.dart';

void main() {
  group('CacheMiddleware', () {
    late CacheMiddleware middleware;

    setUp(() {
      middleware = CacheMiddleware(duration: const Duration(seconds: 1));
    });

    test('should have correct middleware properties', () {
      expect(middleware.name, equals('MemoryCache'));
      expect(middleware.priority, equals(MiddlewarePriority.terminating));
    });

    test('should initialize with default duration', () {
      final defaultMiddleware = CacheMiddleware();
      expect(defaultMiddleware.name, equals('MemoryCache'));
    });

    test('should initialize with custom duration', () {
      final customMiddleware = CacheMiddleware(duration: const Duration(minutes: 5));
      expect(customMiddleware.name, equals('MemoryCache'));
    });
  });
}
