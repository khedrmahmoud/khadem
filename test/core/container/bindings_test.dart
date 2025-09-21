import 'package:test/test.dart';
import '../../../lib/src/core/container/service_container.dart';

class TestService {
  final String name;
  TestService(this.name);
}

void main() {
  group('_Binding (tested through ServiceContainer)', () {
    late ServiceContainer container;

    setUp(() {
      container = ServiceContainer();
    });

    tearDown(() {
      container.flush();
    });

    group('Factory function execution', () {
      test('should call factory function for transient bindings', () {
        var callCount = 0;
        container.bind<TestService>((c) {
          callCount++;
          return TestService('transient-$callCount');
        });

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(callCount, equals(2));
        expect(instance1.name, equals('transient-1'));
        expect(instance2.name, equals('transient-2'));
      });

      test('should call factory function once for singleton bindings', () {
        var callCount = 0;
        container.bind<TestService>((c) {
          callCount++;
          return TestService('singleton-$callCount');
        }, singleton: true,);

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(callCount, equals(1));
        expect(instance1.name, equals('singleton-1'));
        expect(instance2.name, equals('singleton-1'));
        expect(instance1, same(instance2));
      });

      test('should defer factory call for lazy singleton bindings', () {
        var callCount = 0;
        container.lazySingleton<TestService>((c) {
          callCount++;
          return TestService('lazy-$callCount');
        });

        expect(callCount, equals(0));

        final instance1 = container.resolve<TestService>();
        expect(callCount, equals(1));

        final instance2 = container.resolve<TestService>();
        expect(callCount, equals(1)); // Should not increase
        expect(instance1, same(instance2));
      });
    });

    group('Singleton behavior', () {
      test('should cache singleton instances', () {
        container.singleton<TestService>((c) => TestService('singleton'));

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();
        final instance3 = container.resolve<TestService>();

        expect(instance1, same(instance2));
        expect(instance2, same(instance3));
      });

      test('should not cache transient instances', () {
        container.bind<TestService>((c) => TestService('transient'));

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1, isNot(same(instance2)));
      });

      test('should cache lazy singletons after first access', () {
        container.lazySingleton<TestService>((c) => TestService('lazy'));

        // Before resolution
        expect(container.has<TestService>(), isTrue);

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1, same(instance2));
      });
    });

    group('Factory function parameters', () {
      test('should pass container instance to factory', () {
        ServiceContainer? passedContainer;
        container.bind<TestService>((c) {
          passedContainer = c as ServiceContainer;
          return TestService('test');
        });

        container.resolve<TestService>();
        expect(passedContainer, same(container));
      });

      test('should allow factory to resolve other dependencies', () {
        container.bind<String>((c) => 'dependency');
        container.bind<TestService>((c) {
          final dep = c.resolve<String>();
          return TestService('with-$dep');
        });

        final instance = container.resolve<TestService>();
        expect(instance.name, equals('with-dependency'));
      });
    });

    group('Binding lifecycle', () {
      test('should maintain separate instances for different bindings', () {
        container.bind<TestService>((c) => TestService('binding1'));
        container.bind<String>((c) => 'string-binding');

        final service = container.resolve<TestService>();
        final string = container.resolve<String>();

        expect(service.name, equals('binding1'));
        expect(string, equals('string-binding'));
      });

      test('should handle rebinding of same type', () {
        container.bind<TestService>((c) => TestService('first'));
        final first = container.resolve<TestService>();
        expect(first.name, equals('first'));

        container.bind<TestService>((c) => TestService('second'));
        final second = container.resolve<TestService>();
        expect(second.name, equals('second'));
      });
    });

    group('Edge cases', () {
      test('should handle factory functions that return null', () {
        TestService? nullableService;
        container.bind<TestService>((c) => nullableService!);

        // This would throw, but we're testing the binding mechanism
        expect(() => container.resolve<TestService>(), throwsA(isA<TypeError>()));
      });

      test('should handle complex factory functions', () {
        var counter = 0;
        container.bind<TestService>((c) {
          counter++;
          return TestService('instance-$counter');
        });

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1.name, equals('instance-1'));
        expect(instance2.name, equals('instance-2'));
        expect(instance1.name, isNot(equals(instance2.name)));
      });
    });
  });
}
