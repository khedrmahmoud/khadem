import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';

/// Handles registration and management of service providers.
class ServiceProviderRegistry {
  final List<ServiceProvider> _providers = [];
  final Map<Type, ServiceProvider> _deferredProviders = {};
  final ContainerInterface _container;

  ServiceProviderRegistry(this._container);

  /// Returns the list of all registered providers.
  List<ServiceProvider> get providers => List.unmodifiable(_providers);

  /// Registers a single provider.
  void register(ServiceProvider provider) {
    if (provider.isDeferred) {
      for (final type in provider.provides) {
        _deferredProviders[type] = provider;
      }
    } else {
      _providers.add(provider);
      provider.register(_container);
    }
  }

  /// Loads a deferred provider for the given type.
  /// Returns the provider if found and loaded, null otherwise.
  ServiceProvider? loadDeferredProvider(Type type) {
    final provider = _deferredProviders[type];
    if (provider != null) {
      materializeDeferredProvider(provider);
      return provider;
    }
    return null;
  }

  /// Materializes a deferred provider by moving it to the active provider list
  /// and running its register lifecycle step exactly once.
  void materializeDeferredProvider(ServiceProvider provider) {
    _deferredProviders.removeWhere((_, p) => p == provider);

    if (!_providers.contains(provider)) {
      _providers.add(provider);
      provider.register(_container);
    }
  }

  /// Registers multiple providers.
  void registerAll(List<ServiceProvider> providers) {
    for (final provider in providers) {
      register(provider);
    }
  }

  /// Checks if a provider is already registered.
  bool isRegistered(ServiceProvider provider) {
    return _providers.contains(provider) ||
        _deferredProviders.containsValue(provider);
  }

  /// Gets providers by type.
  List<T> getProvidersByType<T extends ServiceProvider>() {
    final all = [..._providers, ..._deferredProviders.values];
    return all.whereType<T>().toList();
  }

  /// Gets deferred providers.
  List<ServiceProvider> getDeferredProviders() {
    return _deferredProviders.values.toSet().toList();
  }

  /// Gets non-deferred providers.
  List<ServiceProvider> getNonDeferredProviders() {
    return _providers.where((provider) => !provider.isDeferred).toList();
  }

  /// Clears all registered providers.
  void clear() {
    _providers.clear();
    _deferredProviders.clear();
  }

  /// Gets the count of registered providers.
  int get count => _providers.length + _deferredProviders.values.toSet().length;
}
