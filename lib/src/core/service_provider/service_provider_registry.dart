import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';

/// Handles registration and management of service providers.
class ServiceProviderRegistry {
  final List<ServiceProvider> _providers = [];
  final ContainerInterface _container;

  ServiceProviderRegistry(this._container);

  /// Returns the list of all registered providers.
  List<ServiceProvider> get providers => List.unmodifiable(_providers);

  /// Registers a single provider.
  void register(ServiceProvider provider) {
    _providers.add(provider);
    provider.register(_container);
  }

  /// Registers multiple providers.
  void registerAll(List<ServiceProvider> providers) {
    for (final provider in providers) {
      register(provider);
    }
  }

  /// Checks if a provider is already registered.
  bool isRegistered(ServiceProvider provider) {
    return _providers.contains(provider);
  }

  /// Gets providers by type.
  List<T> getProvidersByType<T extends ServiceProvider>() {
    return _providers.whereType<T>().toList();
  }

  /// Gets deferred providers.
  List<ServiceProvider> getDeferredProviders() {
    return _providers.where((provider) => provider.isDeferred).toList();
  }

  /// Gets non-deferred providers.
  List<ServiceProvider> getNonDeferredProviders() {
    return _providers.where((provider) => !provider.isDeferred).toList();
  }

  /// Clears all registered providers.
  void clear() {
    _providers.clear();
  }

  /// Gets the count of registered providers.
  int get count => _providers.length;
}
