import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';

/// Manages lifecycle of all service providers (registration + boot).
class ServiceProviderManager {
  final List<ServiceProvider> _providers = [];
  final ContainerInterface _container;
  bool _booted = false;

  ServiceProviderManager(this._container);

  /// Register a single provider and call `register()`.
  void register(ServiceProvider provider) {
    _providers.add(provider);
    provider.register(_container);
  }

  /// Register multiple providers.
  void registerAll(List<ServiceProvider> providers) {
    for (final provider in providers) {
      register(provider);
    }
  }

  /// Boot all registered providers by calling their `boot()` method.
  Future<void> bootAll() async {
    for (final provider in _providers) {
      await provider.boot(_container);
    }
    _booted = true;
  }

  /// Returns the list of all providers.
  List<ServiceProvider> get allProviders => List.unmodifiable(_providers);

  /// Checks if all providers have been booted.
  bool get isBooted => _booted;
}
