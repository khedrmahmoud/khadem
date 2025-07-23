import '../container/container_interface.dart';

/// Base class for creating service providers.
///
/// A service provider registers dependencies and may execute boot logic after registration.
abstract class ServiceProvider {
  /// Called when the provider is registered in the container.
  void register(ContainerInterface container);

  /// Called after all providers are registered (for initialization).
  Future<void> boot(ContainerInterface container) async {}

  /// If true, the provider is deferred and only loaded when its services are requested.
  bool get isDeferred => false;
}
