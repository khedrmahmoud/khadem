/// Container contract that defines the required methods for dependency injection
abstract class ContainerContract {
  /// Bind an implementation to an abstract type
  void bind<T>(T Function() factory);

  /// Bind a singleton implementation
  void singleton<T>(T instance);

  /// Resolve an instance from the container
  T resolve<T>();

  /// Check if the container can resolve a type
  bool canResolve<T>();

  /// Remove a binding from the container
  void unbind<T>();

  /// Clear all bindings
  void clear();
}
