/// Interface for a Dependency Injection (DI) container.
///
/// Provides methods to bind, resolve, and manage dependencies.
abstract interface class ContainerInterface {
  /// Registers a factory for type [T].
  void bind<T>(dynamic Function(ContainerInterface) factory, {bool singleton});

  /// Registers a singleton factory for type [T].
  void singleton<T>(dynamic Function(ContainerInterface) factory);

  /// Registers a lazy singleton (instantiated on first use).
  void lazySingleton<T>(dynamic Function(ContainerInterface) factory);

  /// Registers an existing instance of type [T].
  void instance<T>(T instance);

  /// Registers a contextual binding that applies under specific context key.
  void bindWhen<T>(String context, dynamic Function(ContainerInterface) factory,
      {bool singleton = false});

  /// Resolves an instance of type [T].
  T resolve<T>([String? context]);

  /// Resolves all instances of type [T] (useful for multi-binding).
  List<T> resolveAll<T>();

  /// Checks if a binding exists for type [T].
  bool has<T>([String? context]);

  /// Removes a binding.
  void unbind<T>();

  /// Flushes all bindings and resets the container.
  void flush();
}
