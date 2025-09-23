import 'package:khadem/src/core/container/service_container.dart';
import 'package:khadem/src/support/exceptions/circular_dependency_exception.dart';
import 'package:khadem/src/support/exceptions/service_not_found_exception.dart';
import 'package:test/test.dart';

class TestService {
  final String name;
  TestService(this.name);
}

class DependentService {
  final TestService service;
  DependentService(this.service);
}

class CircularA {
  final CircularB b;
  CircularA(this.b);
}

class CircularB {
  final CircularA a;
  CircularB(this.a);
}

void main() {
  group('ServiceContainer', () {
    late ServiceContainer container;

    setUp(() {
      container = ServiceContainer();
    });

    tearDown(() {
      container.flush();
    });

    group('bind()', () {
      test('should register transient binding', () {
        container.bind<TestService>((c) => TestService('transient'));

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1.name, equals('transient'));
        expect(instance2.name, equals('transient'));
        expect(instance1, isNot(same(instance2)));
      });

      test('should register singleton binding', () {
        container.bind<TestService>(
          (c) => TestService('singleton'),
          singleton: true,
        );

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1.name, equals('singleton'));
        expect(instance2.name, equals('singleton'));
        expect(instance1, same(instance2));
      });

      test('should throw ServiceNotFoundException for unregistered type', () {
        expect(
          () => container.resolve<TestService>(),
          throwsA(isA<ServiceNotFoundException>()),
        );
      });
    });

    group('singleton()', () {
      test('should register singleton binding', () {
        container.singleton<TestService>((c) => TestService('singleton'));

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1, same(instance2));
      });
    });

    group('lazySingleton()', () {
      test('should defer instance creation until first resolution', () {
        var factoryCalled = false;
        container.lazySingleton<TestService>((c) {
          factoryCalled = true;
          return TestService('lazy');
        });

        expect(factoryCalled, isFalse);

        final instance = container.resolve<TestService>();
        expect(factoryCalled, isTrue);
        expect(instance.name, equals('lazy'));
      });

      test('should return same instance on subsequent resolutions', () {
        container.lazySingleton<TestService>((c) => TestService('lazy'));

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();

        expect(instance1, same(instance2));
      });
    });

    group('instance()', () {
      test('should register pre-created instance', () {
        final preCreated = TestService('pre-created');
        container.instance<TestService>(preCreated);

        final resolved = container.resolve<TestService>();
        expect(resolved, same(preCreated));
      });
    });

    group('bindWhen()', () {
      test('should register contextual binding', () {
        container.bind<TestService>((c) => TestService('default'));
        container.bindWhen<TestService>(
          'context1',
          (c) => TestService('contextual'),
        );

        final defaultInstance = container.resolve<TestService>();
        final contextualInstance = container.resolve<TestService>('context1');

        expect(defaultInstance.name, equals('default'));
        expect(contextualInstance.name, equals('contextual'));
      });

      test('should fallback to default binding when context not found', () {
        container.bind<TestService>((c) => TestService('default'));
        container.bindWhen<TestService>(
          'context1',
          (c) => TestService('contextual'),
        );

        final instance = container.resolve<TestService>('unknown-context');
        expect(instance.name, equals('default'));
      });
    });

    group('resolve()', () {
      test('should resolve dependencies', () {
        container.bind<TestService>((c) => TestService('service'));
        container.bind<DependentService>(
          (c) => DependentService(c.resolve<TestService>()),
        );

        final dependent = container.resolve<DependentService>();
        expect(dependent.service.name, equals('service'));
      });

      test('should detect circular dependencies', () {
        container.bind<CircularA>((c) => CircularA(c.resolve<CircularB>()));
        container.bind<CircularB>((c) => CircularB(c.resolve<CircularA>()));

        expect(
          () => container.resolve<CircularA>(),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('should handle complex dependency chains', () {
        container.singleton<TestService>((c) => TestService('root'));
        container.bind<DependentService>(
          (c) => DependentService(c.resolve<TestService>()),
        );

        final root = container.resolve<TestService>();
        final dependent = container.resolve<DependentService>();

        expect(root.name, equals('root'));
        expect(dependent.service.name, equals('root'));
        expect(dependent.service, same(root));
      });
    });

    group('has()', () {
      test('should return true for registered bindings', () {
        container.bind<TestService>((c) => TestService('test'));
        expect(container.has<TestService>(), isTrue);
      });

      test('should return true for registered instances', () {
        container.instance<TestService>(TestService('instance'));
        expect(container.has<TestService>(), isTrue);
      });

      test('should return false for unregistered types', () {
        expect(container.has<TestService>(), isFalse);
      });

      test('should check contextual bindings', () {
        container.bindWhen<TestService>(
          'context',
          (c) => TestService('contextual'),
        );
        expect(container.has<TestService>('context'), isTrue);
        expect(container.has<TestService>('unknown'), isFalse);
      });
    });

    group('unbind()', () {
      test('should remove binding', () {
        container.bind<TestService>((c) => TestService('test'));
        expect(container.has<TestService>(), isTrue);

        container.unbind<TestService>();
        expect(container.has<TestService>(), isFalse);
      });

      test('should remove instance', () {
        container.instance<TestService>(TestService('instance'));
        expect(container.has<TestService>(), isTrue);

        container.unbind<TestService>();
        expect(container.has<TestService>(), isFalse);
      });

      test('should remove contextual binding', () {
        container.bindWhen<TestService>(
          'context',
          (c) => TestService('contextual'),
        );
        expect(container.has<TestService>('context'), isTrue);

        container.unbind<TestService>('context');
        expect(container.has<TestService>('context'), isFalse);
      });

      test('should remove from all contexts when no context specified', () {
        container.bindWhen<TestService>('context1', (c) => TestService('ctx1'));
        container.bindWhen<TestService>('context2', (c) => TestService('ctx2'));

        container.unbind<TestService>();
        expect(container.has<TestService>('context1'), isFalse);
        expect(container.has<TestService>('context2'), isFalse);
      });
    });

    group('flush()', () {
      test('should clear all bindings and instances', () {
        container.bind<TestService>((c) => TestService('binding'));
        container.instance<String>('instance');
        container.bindWhen<TestService>(
          'context',
          (c) => TestService('contextual'),
        );

        expect(container.has<TestService>(), isTrue);
        expect(container.has<String>(), isTrue);
        expect(container.has<TestService>('context'), isTrue);

        container.flush();

        expect(container.has<TestService>(), isFalse);
        expect(container.has<String>(), isFalse);
        expect(container.has<TestService>('context'), isFalse);
      });
    });

    group('Integration tests', () {
      test('should handle complex service graph', () {
        // Register services
        container.singleton<TestService>((c) => TestService('main'));
        container.bind<DependentService>(
          (c) => DependentService(c.resolve<TestService>()),
        );

        // Resolve and verify
        final mainService = container.resolve<TestService>();
        final dependent = container.resolve<DependentService>();

        expect(mainService.name, equals('main'));
        expect(dependent.service, same(mainService));
      });

      test('should maintain singleton instances across resolutions', () {
        var callCount = 0;
        container.singleton<TestService>((c) {
          callCount++;
          return TestService('singleton-$callCount');
        });

        final instance1 = container.resolve<TestService>();
        final instance2 = container.resolve<TestService>();
        final instance3 = container.resolve<TestService>();

        expect(callCount, equals(1));
        expect(instance1, same(instance2));
        expect(instance2, same(instance3));
        expect(instance1.name, equals('singleton-1'));
      });

      test('should handle mixed binding types', () {
        var counter = 0;
        container.singleton<TestService>((c) => TestService('singleton'));
        container.bind<String>((c) => 'transient-${counter++}');

        final singleton1 = container.resolve<TestService>();
        final singleton2 = container.resolve<TestService>();
        final transient1 = container.resolve<String>();
        final transient2 = container.resolve<String>();

        expect(singleton1, same(singleton2));
        expect(transient1, isNot(equals(transient2)));
        expect(transient1, startsWith('transient-'));
        expect(transient2, startsWith('transient-'));
      });
    });
  });
}
