import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';
import 'service_provider_bootloader.dart';
import 'service_provider_registry.dart';
import 'service_provider_validator.dart';

/// Manages lifecycle of all service providers (registration + boot).
/// Uses modular components for better maintainability and separation of concerns.
class ServiceProviderManager {
  late final ServiceProviderRegistry _registry;
  late final ServiceProviderBootloader _bootloader;
  late final ServiceProviderValidator _validator;

  ServiceProviderManager(ContainerInterface container) {
    _registry = ServiceProviderRegistry(container);
    _bootloader = ServiceProviderBootloader(container);
    _validator = ServiceProviderValidator();
  }

  /// Register a single provider and call `register()`.
  void register(ServiceProvider provider) {
    _registry.register(provider);
  }

  /// Register multiple providers.
  void registerAll(List<ServiceProvider> providers) {
    _registry.registerAll(providers);
  }

  /// Boot all registered providers by calling their `boot()` method.
  Future<void> bootAll() async {
    await _bootloader.bootAll(_registry.providers);
  }

  /// Boot only non-deferred providers.
  Future<void> bootNonDeferred() async {
    await _bootloader.bootNonDeferred(_registry.providers);
    // Note: This doesn't set overall booted state since deferred providers may still need booting
  }

  /// Boot only deferred providers.
  Future<void> bootDeferred() async {
    await _bootloader.bootDeferred(_registry.providers);
    // Note: This doesn't set overall booted state since non-deferred providers may still need booting
  }

  /// Returns the list of all providers.
  List<ServiceProvider> get allProviders => _registry.providers;

  /// Checks if all providers have been booted.
  bool get isBooted => _bootloader.isBooted;

  /// Validates all registered providers.
  List<String> validateProviders() {
    return _validator.validateProviders(_registry.providers);
  }

  /// Checks if all providers are valid.
  bool get areAllValid => _validator.areAllValid(_registry.providers);

  /// Gets providers by type.
  List<T> getProvidersByType<T extends ServiceProvider>() {
    return _registry.getProvidersByType<T>();
  }

  /// Gets deferred providers.
  List<ServiceProvider> get deferredProviders => _registry.getDeferredProviders();

  /// Gets non-deferred providers.
  List<ServiceProvider> get nonDeferredProviders => _registry.getNonDeferredProviders();

  /// Gets the count of registered providers.
  int get providerCount => _registry.count;

  /// Clears all registered providers and resets boot state.
  void clear() {
    _registry.clear();
    _bootloader.reset();
  }
}
