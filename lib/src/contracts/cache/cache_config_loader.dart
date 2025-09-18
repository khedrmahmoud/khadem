import '../config/config_contract.dart';
import 'cache_driver.dart';
import 'cache_driver_registry.dart';

/// Interface for cache configuration loading.
/// Defines the contract for loading and parsing cache configuration.
abstract class ICacheConfigLoader {
  /// Loads cache configuration and registers drivers.
  /// Throws [CacheException] if configuration is invalid.
  void loadFromConfig(ConfigInterface config, ICacheDriverRegistry registry);

  /// Creates a cache driver instance from configuration.
  /// Throws [CacheException] if driver type is unknown or configuration is invalid.
  CacheDriver createDriverFromConfig(String driverType, Map<String, dynamic> settings);
}