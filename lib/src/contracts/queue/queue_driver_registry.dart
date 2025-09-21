import 'queue_driver.dart';

/// Interface for queue driver registry management.
/// Defines the contract for registering and retrieving queue drivers.
abstract class IQueueDriverRegistry {
  /// Registers a queue driver with the given name.
  /// Throws [QueueException] if the driver name is empty or already registered.
  void registerDriver(String name, QueueDriver driver);

  /// Gets a queue driver by name.
  /// Returns null if the driver is not registered.
  QueueDriver? getDriver(String name);

  /// Gets all registered driver names.
  List<String> getDriverNames();

  /// Checks if a driver is registered.
  bool hasDriver(String name);

  /// Sets the default queue driver.
  /// Throws [QueueException] if the driver is not registered.
  void setDefaultDriver(String name);

  /// Gets the current default driver.
  QueueDriver getDefaultDriver();

  /// Gets the name of the current default driver.
  String getDefaultDriverName();

  /// Removes a driver from the registry.
  /// Throws [QueueException] if the driver is not registered or is the default driver.
  void removeDriver(String name);

  /// Unregisters a driver from the registry.
   void unregister(String name);
}