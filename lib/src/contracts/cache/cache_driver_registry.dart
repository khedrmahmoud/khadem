import 'cache_driver.dart';

/// Interface for cache driver registry management.
/// Defines the contract for registering and retrieving cache drivers.
abstract class ICacheDriverRegistry {
  /// Registers a cache driver with the given name.
  /// Throws [CacheException] if the driver name is empty or already registered.
  void registerDriver(String name, CacheDriver driver);

  /// Gets a cache driver by name.
  /// Returns null if the driver is not registered.
  CacheDriver? getDriver(String name);

  /// Gets all registered driver names.
  List<String> getDriverNames();

  /// Checks if a driver is registered.
  bool hasDriver(String name);

  /// Sets the default cache driver.
  /// Throws [CacheException] if the driver is not registered.
  void setDefaultDriver(String name);

  /// Gets the current default driver.
  CacheDriver getDefaultDriver();

  /// Gets the name of the current default driver.
  String getDefaultDriverName();

  /// Removes a driver from the registry.
  /// Throws [CacheException] if the driver is not registered or is the default driver.
  void removeDriver(String name);
}
