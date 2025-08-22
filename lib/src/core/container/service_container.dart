import '../../contracts/container/container_interface.dart';
import '../../support/exceptions/circular_dependency_exception.dart';
import '../../support/exceptions/service_not_found_exception.dart';
part 'bindings.dart';

/// A more powerful dependency injection container with support for interfaces,
/// factories, and contextual binding.
class ServiceContainer implements ContainerInterface {
  final Map<Type, _Binding> _bindings = {};
  final Map<String, Map<Type, _Binding>> _contextualBindings = {};
  final Map<Type, dynamic> _instances = {};
  final List<Type> _resolving = [];

  /// Binds an implementation to an abstract type.
  @override
  void bind<T>(dynamic Function(ContainerInterface) factory,
      {bool singleton = false}) {
    _bindings[T] = _Binding(factory, singleton: singleton);
  }

  /// Binds an implementation to an interface when requested within a specific context.
  @override
  void bindWhen<T>(String context, dynamic Function(ContainerInterface) factory,
      {bool singleton = false}) {
    _contextualBindings[context] ??= {};
    _contextualBindings[context]![T] = _Binding(factory, singleton: singleton);
  }

  /// Registers a singleton instance.
  @override
  void singleton<T>(dynamic Function(ContainerInterface) factory) {
    bind<T>(factory, singleton: true);
  }

  /// Registers a lazy singleton instance.
  @override
  void lazySingleton<T>(dynamic Function(ContainerInterface) factory) {
    _bindings[T] = _Binding(factory, singleton: true, lazy: true);
  }

  /// Registers an already created instance as a singleton.
  @override
  void instance<T>(T instance) {
    _instances[T] = instance;
  }

  /// Resolves a type from the container.
  @override
  T resolve<T>([String? context]) {
    if (_resolving.contains(T)) {
      throw CircularDependencyException(
          'Circular dependency detected while resolving $T');
    }

    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }

    _Binding? binding;
    if (context != null && _contextualBindings.containsKey(context)) {
      binding = _contextualBindings[context]![T];
    }
    binding ??= _bindings[T];

    if (binding == null) {
      throw ServiceNotFoundException('Service $T not registered');
    }

    _resolving.add(T);
    try {
      final instance = binding.getInstance(this);

      if (binding.singleton && !binding.lazy) {
        _instances[T] = instance;
      }

      return instance as T;
    } finally {
      _resolving.remove(T);
    }
  }

  /// Resolves all registered implementations of a given type.
  @override

  /// Resolves and returns all registered instances that are assignable to the specified type.
  List<T> resolveAll<T>() {
    final result = <T>[];
    for (final type in _bindings.keys) {
      result.add(resolve<T>());
    }
    return result;
  }

  /// Checks if a service is registered.
  @override
  bool has<T>([String? context]) {
    if (context != null) {
      return _contextualBindings[context]?.containsKey(T) ?? false;
    }

    return _bindings.containsKey(T) || _instances.containsKey(T);
  }

  /// Removes a service registration.
  @override
  void unbind<T>([String? context]) {
    if (context != null) {
      _contextualBindings[context]?.remove(T);
    } else {
      _bindings.remove(T);
      _instances.remove(T);
      for (final ctx in _contextualBindings.keys) {
        _contextualBindings[ctx]?.remove(T);
      }
    }
  }

  /// Clears all bindings and instances.
  @override
  void flush() {
    _bindings.clear();
    _instances.clear();
    _contextualBindings.clear();
  }
}
