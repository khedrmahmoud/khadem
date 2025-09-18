import 'package:test/test.dart';
import '../../../lib/src/core/container/container_provider.dart';
import '../../../lib/src/core/container/service_container.dart';

class TestService {
  final String id;
  TestService(this.id);
}

class MockLogger {
  void log(String message) {}
}

class MockDatabase {
  final MockLogger logger;
  MockDatabase(this.logger);
}

class MockUserService {
  final MockDatabase db;
  final MockLogger logger;
  MockUserService(this.db, this.logger);
}

void main() {
  group('ContainerProvider', () {
    tearDown(() {
      // Reset the container after each test
      ContainerProvider.instance.flush();
    });

    group('instance', () {
      test('should return singleton instance', () {
        final instance1 = ContainerProvider.instance;
        final instance2 = ContainerProvider.instance;

        expect(instance1, same(instance2));
        expect(instance1, isA<ServiceContainer>());
      });

      test('should maintain state across accesses', () {
        final container = ContainerProvider.instance;
        container.bind<TestService>((c) => TestService('test'));

        final resolved = container.resolve<TestService>();
        expect(resolved.id, equals('test'));
      });

      test('should persist bindings across different accesses', () {
        // Register via first access
        ContainerProvider.instance.bind<TestService>((c) => TestService('persistent'));

        // Access via second reference
        final container2 = ContainerProvider.instance;
        final resolved = container2.resolve<TestService>();

        expect(resolved.id, equals('persistent'));
      });
    });

    group('Integration with ServiceContainer', () {
      test('should support all ServiceContainer features', () {
        final provider = ContainerProvider.instance;

        // Test binding
        provider.bind<TestService>((c) => TestService('bound'));
        final bound = provider.resolve<TestService>();
        expect(bound.id, equals('bound'));

        // Test singleton
        provider.singleton<TestService>((c) => TestService('singleton'));
        final singleton1 = provider.resolve<TestService>();
        final singleton2 = provider.resolve<TestService>();
        expect(singleton1, same(singleton2));

        // Test instance registration
        final preCreated = TestService('pre-created');
        provider.instance<TestService>(preCreated);
        final resolved = provider.resolve<TestService>();
        expect(resolved, same(preCreated));

        // Test has
        expect(provider.has<TestService>(), isTrue);

        // Test unbind
        provider.unbind<TestService>();
        expect(provider.has<TestService>(), isFalse);
      });

      test('should handle complex dependency injection', () {
        final provider = ContainerProvider.instance;

        // Register dependencies
        provider.singleton<MockLogger>((c) => MockLogger());
        provider.bind<MockDatabase>((c) => MockDatabase(c.resolve<MockLogger>()));
        provider.bind<MockUserService>((c) => MockUserService(
          c.resolve<MockDatabase>(),
          c.resolve<MockLogger>(),
        ),);

        // Resolve service
        final userService = provider.resolve<MockUserService>();

        expect(userService, isNotNull);
        expect(userService.db, isNotNull);
        expect(userService.logger, isNotNull);
        // Logger should be the same instance due to singleton
        expect(userService.db.logger, same(userService.logger));
      });
    });

    group('Thread safety considerations', () {
      test('should handle concurrent access patterns', () {
        final provider = ContainerProvider.instance;

        // Simulate multiple services being registered
        provider.bind<String>((c) => 'service1');
        provider.bind<int>((c) => 42);
        provider.bind<bool>((c) => true);

        // All should be resolvable
        expect(provider.resolve<String>(), equals('service1'));
        expect(provider.resolve<int>(), equals(42));
        expect(provider.resolve<bool>(), isTrue);
      });
    });
  });
}
