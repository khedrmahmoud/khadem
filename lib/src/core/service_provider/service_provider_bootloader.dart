import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';

/// Handles the booting process of service providers.
class ServiceProviderBootloader {
  final ContainerInterface _container;
  bool _booted = false;

  ServiceProviderBootloader(this._container);

  /// Returns whether all providers have been booted.
  bool get isBooted => _booted;

  /// Boots a single provider.
  Future<void> bootProvider(ServiceProvider provider) async {
    await provider.boot(_container);
  }

  /// Boots multiple providers sequentially.
  Future<void> bootProviders(List<ServiceProvider> providers) async {
    for (final provider in providers) {
      await bootProvider(provider);
    }
  }

  /// Boots all providers and marks as booted.
  Future<void> bootAll(List<ServiceProvider> providers) async {
    await bootProviders(providers);
    _booted = true;
  }

  /// Boots only non-deferred providers.
  Future<void> bootNonDeferred(List<ServiceProvider> providers) async {
    final nonDeferred = providers.where((provider) => !provider.isDeferred).toList();
    await bootProviders(nonDeferred);
  }

  /// Boots only deferred providers.
  Future<void> bootDeferred(List<ServiceProvider> providers) async {
    final deferred = providers.where((provider) => provider.isDeferred).toList();
    await bootProviders(deferred);
  }

  /// Resets the boot state.
  void reset() {
    _booted = false;
  }
}
