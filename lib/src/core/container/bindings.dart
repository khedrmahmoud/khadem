part of 'service_container.dart';

/// Represents a binding inside the container.
///
/// A binding encapsulates the factory function used to create instances,
/// along with configuration options like singleton behavior and lazy loading.
/// This class is internal to the container and manages instance caching
/// for singleton bindings.
class _Binding {
  /// The factory function that creates the instance.
  ///
  /// This function receives the container as a parameter, allowing
  /// for dependency resolution during instance creation.
  final dynamic Function(ContainerInterface) factory;

  /// Whether this binding should create a singleton instance.
  ///
  /// When true, the same instance will be returned for all resolutions
  /// of this type. When false, a new instance is created each time.
  final bool singleton;

  /// Whether this binding should be lazily instantiated.
  ///
  /// Lazy bindings defer instance creation until first access.
  /// Only applies when [singleton] is also true.
  final bool lazy;

  /// Cached instance for lazy singleton bindings.
  ///
  /// This holds the instance once it's been created for lazy singletons,
  /// ensuring the factory is only called once.
  dynamic _lazyInstance;

  /// Creates a new binding with the specified factory and options.
  ///
  /// [factory] - The function that creates the instance
  /// [singleton] - Whether to cache and reuse the instance
  /// [lazy] - Whether to defer creation until first access (singleton only)
  _Binding(this.factory, {this.singleton = false, this.lazy = false});

  /// Returns the instance for this binding.
  ///
  /// For regular bindings, calls the factory each time.
  /// For singleton bindings, returns the cached instance.
  /// For lazy singleton bindings, creates and caches on first access.
  ///
  /// [container] - The container instance for dependency resolution
  /// Returns the created or cached instance
  dynamic getInstance(ContainerInterface container) {
    if (singleton && lazy) {
      return _lazyInstance ??= factory(container);
    }
    return factory(container);
  }
}
