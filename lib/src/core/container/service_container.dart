import '../../contracts/container/container_interface.dart';
import '../../support/exceptions/circular_dependency_exception.dart';
import '../../support/exceptions/service_not_found_exception.dart';
part 'bindings.dart';

/// A powerful dependency injection container with advanced features.
///
/// The ServiceContainer provides a robust dependency injection system
/// supporting interfaces, contextual bindings, singletons, lazy loading,
/// and circular dependency detection. It implements the [ContainerInterface]
/// and serves as the core of the framework's service management.
///
/// Key features:
/// - Type-safe dependency resolution using generics
/// - Singleton and transient binding modes
/// - Lazy singleton instantiation
/// - Contextual bindings for different resolution contexts
/// - Circular dependency detection and prevention
/// - Instance registration for pre-created objects
///
/// Example usage:
/// ```dart
/// final container = ServiceContainer();
///
/// // Register a transient service
/// container.bind<Logger>((c) => ConsoleLogger());
///
/// // Register a singleton
/// container.singleton<Database>((c) => Database.connect());
///
/// // Register with dependencies
/// container.bind<UserService>((c) => UserService(
///   c.resolve<Logger>(),
///   c.resolve<Database>(),
/// ));
///
/// // Resolve services
/// final userService = container.resolve<UserService>();
/// ```
class ServiceContainer implements ContainerInterface {
  /// Internal storage for type bindings.
  ///
  /// Maps abstract types to their concrete factory bindings.
  final Map<Type, _Binding> _bindings = {};

  /// Internal storage for contextual bindings.
  ///
  /// Maps context strings to type-specific bindings, allowing
  /// different implementations based on resolution context.
  final Map<String, Map<Type, _Binding>> _contextualBindings = {};

  /// Internal storage for singleton instances.
  ///
  /// Caches resolved singleton instances to ensure the same
  /// instance is returned for subsequent resolutions.
  final Map<Type, dynamic> _instances = {};

  /// Stack of types currently being resolved.
  ///
  /// Used to detect circular dependencies during resolution.
  final List<Type> _resolving = [];

  /// Binds an implementation to an abstract type.
  ///
  /// Registers a factory function that will be used to create instances
  /// of the specified type. By default, creates a new instance each time
  /// the type is resolved (transient binding).
  ///
  /// [T] - The abstract type to bind
  /// [factory] - Factory function that creates the instance
  /// [singleton] - Whether to cache and reuse the instance
  @override
  void bind<T>(dynamic Function(ContainerInterface) factory,
      {bool singleton = false,}) {
    _bindings[T] = _Binding(factory, singleton: singleton);
  }

  /// Binds an implementation to an interface when requested within a specific context.
  ///
  /// Allows different implementations of the same interface to be used
  /// in different contexts. The context is specified during resolution.
  ///
  /// [T] - The abstract type to bind
  /// [context] - The context identifier for this binding
  /// [factory] - Factory function that creates the instance
  /// [singleton] - Whether to cache and reuse the instance
  @override
  void bindWhen<T>(String context, dynamic Function(ContainerInterface) factory,
      {bool singleton = false,}) {
    _contextualBindings[context] ??= {};
    _contextualBindings[context]![T] = _Binding(factory, singleton: singleton);
  }

  /// Registers a singleton instance.
  ///
  /// Creates a binding that will cache the first created instance
  /// and return it for all subsequent resolutions.
  ///
  /// [T] - The type to register as singleton
  /// [factory] - Factory function that creates the instance
  @override
  void singleton<T>(dynamic Function(ContainerInterface) factory) {
    bind<T>(factory, singleton: true);
  }

  /// Registers a lazy singleton instance.
  ///
  /// Creates a singleton binding that defers instance creation
  /// until the first time it's resolved, improving startup performance.
  ///
  /// [T] - The type to register as lazy singleton
  /// [factory] - Factory function that creates the instance
  @override
  void lazySingleton<T>(dynamic Function(ContainerInterface) factory) {
    _bindings[T] = _Binding(factory, singleton: true, lazy: true);
  }

  /// Registers an already created instance as a singleton.
  ///
  /// Useful for registering pre-configured objects or third-party
  /// instances that don't need factory functions.
  ///
  /// [T] - The type of the instance
  /// [instance] - The pre-created instance to register
  @override
  void instance<T>(T instance) {
    _instances[T] = instance;
  }

  /// Resolves a type from the container.
  ///
  /// Creates or retrieves an instance of the specified type.
  /// Handles singleton caching, contextual resolution, and
  /// circular dependency detection.
  ///
  /// [T] - The type to resolve
  /// [context] - Optional context for contextual bindings
  /// Returns the resolved instance
  /// Throws [ServiceNotFoundException] if the type is not registered
  /// Throws [CircularDependencyException] if circular dependency detected
  @override
  T resolve<T>([String? context]) {
    if (_resolving.contains(T)) {
      throw CircularDependencyException(
          'Circular dependency detected while resolving $T',);
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
  ///
  /// Note: This implementation has a bug - it tries to resolve T for all
  /// registered types, which will likely fail. This should be fixed to
  /// properly resolve all implementations that are assignable to T.
  @override
  List<T> resolveAll<T>() {
    final List<T> result = [];

    // Resolve the main binding if it exists
    if (_bindings.containsKey(T) || _instances.containsKey(T)) {
      result.add(resolve<T>());
    }

    // Resolve all contextual bindings for T
    for (final context in _contextualBindings.keys) {
      if (_contextualBindings[context]!.containsKey(T)) {
        result.add(resolve<T>(context));
      }
    }

    return result;
  }

  /// Checks if a service is registered.
  ///
  /// Verifies whether a binding or instance exists for the specified type,
  /// optionally within a specific context.
  ///
  /// [T] - The type to check
  /// [context] - Optional context to check within
  /// Returns true if the service is registered
  @override
  bool has<T>([String? context]) {
    if (context != null) {
      return _contextualBindings[context]?.containsKey(T) ?? false;
    }

    return _bindings.containsKey(T) || _instances.containsKey(T);
  }

  /// Removes a service registration.
  ///
  /// Unbinds the specified type from the container, optionally
  /// within a specific context. Also removes any cached instances.
  ///
  /// [T] - The type to unbind
  /// [context] - Optional context to unbind from
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
  ///
  /// Resets the container to its initial state, removing all
  /// registered bindings, cached instances, and contextual bindings.
  /// Useful for testing or reinitializing the container.
  @override
  void flush() {
    _bindings.clear();
    _instances.clear();
    _contextualBindings.clear();
  }
}
