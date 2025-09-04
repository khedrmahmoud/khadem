import 'dart:async';

import 'package:test/test.dart';

import '../../../lib/src/contracts/container/container_interface.dart';
import '../../../lib/src/contracts/provider/service_provider.dart';
import '../../../lib/src/core/service_provider/index.dart';

// Mock container for testing
class MockContainer implements ContainerInterface {
  final Map<Type, dynamic> _bindings = {};

  @override
  void bind<T>(dynamic Function(ContainerInterface) factory, {bool singleton = false}) {
    _bindings[T] = factory;
  }

  @override
  void singleton<T>(dynamic Function(ContainerInterface) factory) {
    bind<T>(factory, singleton: true);
  }

  @override
  void lazySingleton<T>(dynamic Function(ContainerInterface) factory) {
    bind<T>(factory, singleton: true);
  }

  @override
  void instance<T>(T instance) {
    _bindings[T] = instance;
  }

  @override
  void bindWhen<T>(String context, dynamic Function(ContainerInterface) factory,
      {bool singleton = false,}) {
    // Not implemented for this test
  }

  @override
  T resolve<T>([String? context]) {
    final binding = _bindings[T];
    if (binding is Function) {
      return binding(this) as T;
    }
    return binding as T;
  }

  @override
  List<T> resolveAll<T>() {
    // Not implemented for this test
    return [];
  }

  @override
  bool has<T>([String? context]) {
    return _bindings.containsKey(T);
  }

  @override
  void unbind<T>() {
    _bindings.remove(T);
  }

  @override
  void flush() {
    _bindings.clear();
  }
}

// Test service providers
class TestServiceProvider extends ServiceProvider {
  bool registered = false;
  bool booted = false;

  @override
  void register(ContainerInterface container) {
    registered = true;
    container.bind<String>((c) => 'test-service');
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    booted = true;
  }
}

class DeferredServiceProvider extends ServiceProvider {
  bool registered = false;
  bool booted = false;

  @override
  void register(ContainerInterface container) {
    registered = true;
    container.bind<int>((c) => 42);
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    booted = true;
  }

  @override
  bool get isDeferred => true;
}

class FailingServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    throw Exception('Registration failed');
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    throw Exception('Boot failed');
  }
}

class FailingBootServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    // Registration succeeds
    container.bind<String>((c) => 'failing-service');
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    throw Exception('Boot failed');
  }
}

void main() {
  group('ServiceProviderRegistry', () {
    late MockContainer container;
    late ServiceProviderRegistry registry;

    setUp(() {
      container = MockContainer();
      registry = ServiceProviderRegistry(container);
    });

    tearDown(() {
      registry.clear();
    });

    group('Provider Registration', () {
      test('should register single provider', () {
        final provider = TestServiceProvider();
        registry.register(provider);

        expect(registry.providers.length, equals(1));
        expect(registry.providers.first, equals(provider));
        expect(provider.registered, isTrue);
      });

      test('should register multiple providers', () {
        final provider1 = TestServiceProvider();
        final provider2 = TestServiceProvider();
        final providers = [provider1, provider2];

        registry.registerAll(providers);

        expect(registry.providers.length, equals(2));
        expect(provider1.registered, isTrue);
        expect(provider2.registered, isTrue);
      });

      test('should check if provider is registered', () {
        final provider = TestServiceProvider();
        expect(registry.isRegistered(provider), isFalse);

        registry.register(provider);
        expect(registry.isRegistered(provider), isTrue);
      });

      test('should get providers by type', () {
        final testProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        registry.register(testProvider);
        registry.register(deferredProvider);

        final testProviders = registry.getProvidersByType<TestServiceProvider>();
        expect(testProviders.length, equals(1));
        expect(testProviders.first, equals(testProvider));
      });

      test('should get deferred providers', () {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        registry.register(regularProvider);
        registry.register(deferredProvider);

        final deferred = registry.getDeferredProviders();
        expect(deferred.length, equals(1));
        expect(deferred.first, equals(deferredProvider));
      });

      test('should get non-deferred providers', () {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        registry.register(regularProvider);
        registry.register(deferredProvider);

        final nonDeferred = registry.getNonDeferredProviders();
        expect(nonDeferred.length, equals(1));
        expect(nonDeferred.first, equals(regularProvider));
      });

      test('should clear all providers', () {
        registry.register(TestServiceProvider());
        registry.register(DeferredServiceProvider());
        expect(registry.count, equals(2));

        registry.clear();
        expect(registry.count, equals(0));
        expect(registry.providers, isEmpty);
      });

      test('should return correct count', () {
        expect(registry.count, equals(0));

        registry.register(TestServiceProvider());
        expect(registry.count, equals(1));

        registry.register(DeferredServiceProvider());
        expect(registry.count, equals(2));
      });
    });
  });

  group('ServiceProviderBootloader', () {
    late MockContainer container;
    late ServiceProviderBootloader bootloader;

    setUp(() {
      container = MockContainer();
      bootloader = ServiceProviderBootloader(container);
    });

    group('Provider Booting', () {
      test('should boot single provider', () async {
        final provider = TestServiceProvider();
        await bootloader.bootProvider(provider);

        expect(provider.booted, isTrue);
        expect(bootloader.isBooted, isFalse); // Single boot doesn't set overall booted state
      });

      test('should boot multiple providers', () async {
        final provider1 = TestServiceProvider();
        final provider2 = TestServiceProvider();
        final providers = [provider1, provider2];

        await bootloader.bootProviders(providers);

        expect(provider1.booted, isTrue);
        expect(provider2.booted, isTrue);
      });

      test('should boot all providers and set booted state', () async {
        final provider1 = TestServiceProvider();
        final provider2 = TestServiceProvider();
        final providers = [provider1, provider2];

        await bootloader.bootAll(providers);

        expect(provider1.booted, isTrue);
        expect(provider2.booted, isTrue);
        expect(bootloader.isBooted, isTrue);
      });

      test('should boot only non-deferred providers', () async {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();
        final providers = [regularProvider, deferredProvider];

        await bootloader.bootNonDeferred(providers);

        expect(regularProvider.booted, isTrue);
        expect(deferredProvider.booted, isFalse);
      });

      test('should boot only deferred providers', () async {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();
        final providers = [regularProvider, deferredProvider];

        await bootloader.bootDeferred(providers);

        expect(regularProvider.booted, isFalse);
        expect(deferredProvider.booted, isTrue);
      });

      test('should reset boot state', () {
        bootloader.reset();
        expect(bootloader.isBooted, isFalse);
      });
    });
  });

  group('ServiceProviderValidator', () {
    late ServiceProviderValidator validator;

    setUp(() {
      validator = ServiceProviderValidator();
    });

    group('Provider Validation', () {
      test('should validate single provider', () {
        final provider = TestServiceProvider();
        expect(validator.validateProvider(provider), isTrue);
      });

      test('should validate multiple providers', () {
        final providers = [TestServiceProvider(), DeferredServiceProvider()];
        final errors = validator.validateProviders(providers);

        expect(errors, isEmpty);
      });

      test('should detect duplicate providers', () {
        final provider = TestServiceProvider();
        final providers = [provider, provider];
        final errors = validator.validateProviders(providers);

        expect(errors, isNotEmpty);
        expect(errors.first, contains('Duplicate providers'));
      });

      test('should return true when all providers are valid', () {
        final providers = [TestServiceProvider(), DeferredServiceProvider()];
        expect(validator.areAllValid(providers), isTrue);
      });

      test('should return false when providers are invalid', () {
        final provider = TestServiceProvider();
        final providers = [provider, provider];
        expect(validator.areAllValid(providers), isFalse);
      });
    });
  });

  group('ServiceProviderManager Integration', () {
    late MockContainer container;
    late ServiceProviderManager manager;

    setUp(() {
      container = MockContainer();
      manager = ServiceProviderManager(container);
    });

    tearDown(() {
      manager.clear();
    });

    group('Provider Registration', () {
      test('should register single provider', () {
        final provider = TestServiceProvider();
        manager.register(provider);

        expect(manager.allProviders.length, equals(1));
        expect(manager.allProviders.first, equals(provider));
        expect(provider.registered, isTrue);
      });

      test('should register multiple providers', () {
        final provider1 = TestServiceProvider();
        final provider2 = DeferredServiceProvider();
        final providers = [provider1, provider2];

        manager.registerAll(providers);

        expect(manager.allProviders.length, equals(2));
        expect(provider1.registered, isTrue);
        expect(provider2.registered, isTrue);
      });

      test('should boot all providers', () async {
        final provider1 = TestServiceProvider();
        final provider2 = DeferredServiceProvider();

        manager.register(provider1);
        manager.register(provider2);

        await manager.bootAll();

        expect(provider1.booted, isTrue);
        expect(provider2.booted, isTrue);
        expect(manager.isBooted, isTrue);
      });

      test('should boot only non-deferred providers', () async {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        manager.register(regularProvider);
        manager.register(deferredProvider);

        await manager.bootNonDeferred();

        expect(regularProvider.booted, isTrue);
        expect(deferredProvider.booted, isFalse);
        expect(manager.isBooted, isFalse); // Partial boot doesn't set overall booted state
      });

      test('should boot only deferred providers', () async {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        manager.register(regularProvider);
        manager.register(deferredProvider);

        await manager.bootDeferred();

        expect(regularProvider.booted, isFalse);
        expect(deferredProvider.booted, isTrue);
        expect(manager.isBooted, isFalse); // Partial boot doesn't set overall booted state
      });

      test('should validate providers', () {
        final provider1 = TestServiceProvider();
        final provider2 = DeferredServiceProvider();

        manager.register(provider1);
        manager.register(provider2);

        final errors = manager.validateProviders();
        expect(errors, isEmpty);
        expect(manager.areAllValid, isTrue);
      });

      test('should get providers by type', () {
        final testProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        manager.register(testProvider);
        manager.register(deferredProvider);

        final testProviders = manager.getProvidersByType<TestServiceProvider>();
        expect(testProviders.length, equals(1));
        expect(testProviders.first, equals(testProvider));
      });

      test('should get deferred and non-deferred providers', () {
        final regularProvider = TestServiceProvider();
        final deferredProvider = DeferredServiceProvider();

        manager.register(regularProvider);
        manager.register(deferredProvider);

        expect(manager.deferredProviders.length, equals(1));
        expect(manager.nonDeferredProviders.length, equals(1));
        expect(manager.deferredProviders.first, equals(deferredProvider));
        expect(manager.nonDeferredProviders.first, equals(regularProvider));
      });

      test('should return correct provider count', () {
        expect(manager.providerCount, equals(0));

        manager.register(TestServiceProvider());
        expect(manager.providerCount, equals(1));

        manager.register(DeferredServiceProvider());
        expect(manager.providerCount, equals(2));
      });

      test('should clear all providers and reset state', () async {
        final provider = TestServiceProvider();
        manager.register(provider);
        await manager.bootAll();

        expect(manager.providerCount, equals(1));
        expect(manager.isBooted, isTrue);

        manager.clear();

        expect(manager.providerCount, equals(0));
        expect(manager.isBooted, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle provider registration errors gracefully', () {
        final failingProvider = FailingServiceProvider();

        expect(() => manager.register(failingProvider), throwsException);
      });

      test('should handle provider boot errors gracefully', () async {
        final failingProvider = FailingBootServiceProvider();
        manager.register(failingProvider);

        expect(() => manager.bootAll(), throwsException);
      });
    });

    group('State Management', () {
      test('should maintain correct boot state', () async {
        expect(manager.isBooted, isFalse);

        final provider = TestServiceProvider();
        manager.register(provider);
        await manager.bootAll();

        expect(manager.isBooted, isTrue);

        manager.clear();
        expect(manager.isBooted, isFalse);
      });

      test('should provide immutable provider list', () {
        final providers = manager.allProviders;
        expect(() => providers.add(TestServiceProvider()), throwsUnsupportedError);
      });
    });
  });
}
