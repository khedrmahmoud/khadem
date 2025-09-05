import '../../contracts/queue/queue_driver.dart';

/// Registry for managing queue drivers.
/// Provides centralized registration and resolution of queue drivers.
class QueueDriverRegistry {
  final Map<String, QueueDriver> _drivers = {};

  /// Registers a queue driver with the given name.
  void register(String name, QueueDriver driver) {
    _drivers[name] = driver;
  }

  /// Unregisters a queue driver.
  void unregister(String name) {
    _drivers.remove(name);
  }

  /// Gets a registered driver by name.
  QueueDriver? getDriver(String name) {
    return _drivers[name];
  }

  /// Gets all registered driver names.
  Set<String> getDriverNames() {
    return Set.from(_drivers.keys);
  }

  /// Checks if a driver is registered.
  bool hasDriver(String name) {
    return _drivers.containsKey(name);
  }

  /// Clears all registered drivers.
  void clear() {
    _drivers.clear();
  }
}
