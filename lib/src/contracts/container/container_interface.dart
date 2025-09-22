/// Interface for a Dependency Injection (DI) container.
///
/// This interface defines the contract for a container that manages dependencies
/// in an application. It supports various binding types such as factories, singletons,
/// lazy singletons, and instances. Contextual bindings allow for different resolutions
/// based on a context key, enabling flexible dependency management.
///
/// The container provides methods to register dependencies (`bind`, `singleton`, etc.),
/// resolve them (`resolve`, `resolveAll`), check for existence (`has`), and manage
/// the container state (`unbind`, `flush`).
///
/// Example usage:
/// ```dart
/// class MyContainer implements ContainerInterface {
///   // Implementation details...
/// }
/// ```
///
/// Note: Implementations should handle type safety and ensure thread-safety if needed.
abstract interface class ContainerInterface {
  /// Registers a factory function for type [T].
  ///
  /// The factory is called each time [T] is resolved, unless [singleton] is true.
  /// If [singleton] is true, the instance is created once and reused.
  ///
  /// - [factory]: A function that takes the container and returns an instance of [T].
  /// - [singleton]: If true, the factory is treated as a singleton.
  ///
  /// Throws an exception if a binding for [T] already exists.
  void bind<T>(dynamic Function(ContainerInterface) factory, {bool singleton});

  /// Registers a singleton factory for type [T].
  ///
  /// The factory is called once, and the instance is reused for all subsequent resolutions.
  /// This is equivalent to calling [bind] with [singleton] set to true.
  ///
  /// - [factory]: A function that takes the container and returns an instance of [T].
  ///
  /// Throws an exception if a binding for [T] already exists.
  void singleton<T>(dynamic Function(ContainerInterface) factory);

  /// Registers a lazy singleton factory for type [T].
  ///
  /// The factory is called only on the first resolution of [T], and the instance is cached
  /// for future use. This differs from [singleton] in that the instance is not created
  /// until first needed.
  ///
  /// - [factory]: A function that takes the container and returns an instance of [T].
  ///
  /// Throws an exception if a binding for [T] already exists.
  void lazySingleton<T>(dynamic Function(ContainerInterface) factory);

  /// Registers an existing instance of type [T] as a singleton.
  ///
  /// The provided instance is used directly for all resolutions of [T].
  ///
  /// - [instance]: The instance to register.
  ///
  /// Throws an exception if a binding for [T] already exists.
  void instance<T>(T instance);

  /// Registers a contextual binding for type [T] under a specific [context].
  ///
  /// This allows different factories for [T] based on the context provided during resolution.
  /// If [singleton] is true, the instance is created once per context and reused.
  ///
  /// - [context]: A string key identifying the context.
  /// - [factory]: A function that takes the container and returns an instance of [T].
  /// - [singleton]: If true, the factory is treated as a singleton within the context.
  ///
  /// Throws an exception if a binding for [T] under the same [context] already exists.
  void bindWhen<T>(
    String context,
    dynamic Function(ContainerInterface) factory, {
    bool singleton = false,
  });

  /// Resolves and returns an instance of type [T].
  ///
  /// If a [context] is provided, it uses the contextual binding for that key.
  /// Otherwise, it uses the default binding for [T].
  ///
  /// - [context]: Optional context key for contextual resolution.
  ///
  /// Returns the resolved instance of [T].
  ///
  /// Throws an exception if no binding exists for [T] or if resolution fails.
  T resolve<T>([String? context]);

  /// Resolves and returns all instances of type [T].
  ///
  /// This is useful for multi-bindings where multiple factories are registered for [T].
  /// It collects all available instances based on registered bindings.
  ///
  /// Returns a list of resolved instances of [T].
  ///
  /// Throws an exception if no bindings exist for [T] or if resolution fails.
  List<T> resolveAll<T>();

  /// Checks if a binding exists for type [T].
  ///
  /// If a [context] is provided, it checks for a contextual binding under that key.
  /// Otherwise, it checks for the default binding.
  ///
  /// - [context]: Optional context key to check.
  ///
  /// Returns true if a binding exists, false otherwise.
  bool has<T>([String? context]);

  /// Removes the binding for type [T].
  ///
  /// This unbinds [T] from the container, including any contextual bindings.
  /// After unbinding, [T] can no longer be resolved until rebound.
  ///
  /// Throws an exception if no binding exists for [T].
  void unbind<T>();

  /// Flushes all bindings and resets the container to its initial state.
  ///
  /// This removes all registered factories, instances, and contexts, effectively
  /// clearing the container. Useful for testing or reinitialization.
  void flush();
}
