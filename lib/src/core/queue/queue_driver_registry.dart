import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_driver_registry.dart';
import '../../support/exceptions/queue_exception.dart';

/// Registry for managing queue drivers.
/// Provides centralized registration and resolution of queue drivers.
class QueueDriverRegistry implements IQueueDriverRegistry {
  final Map<String, QueueDriver> _drivers = {};
  String? _defaultDriverName;

  @override
  void registerDriver(String name, QueueDriver driver) {
    if (name.isEmpty) {
      throw QueueException('Driver name cannot be empty');
    }
    if (_drivers.containsKey(name)) {
      throw QueueException('Driver "$name" is already registered');
    }
    _drivers[name] = driver;

    // Set as default if it's the first driver
    if (_defaultDriverName == null) {
      _defaultDriverName = name;
    }
  }

  @override
  void unregister(String name) {
    if (!_drivers.containsKey(name)) {
      throw QueueException('Driver "$name" is not registered');
    }
    if (_defaultDriverName == name) {
      throw QueueException('Cannot unregister the default driver "$name"');
    }
    _drivers.remove(name);
  }

  @override
  QueueDriver? getDriver(String name) {
    return _drivers[name];
  }

  @override
  List<String> getDriverNames() {
    return _drivers.keys.toList();
  }

  @override
  bool hasDriver(String name) {
    return _drivers.containsKey(name);
  }

  @override
  void setDefaultDriver(String name) {
    if (!_drivers.containsKey(name)) {
      throw QueueException('Driver "$name" is not registered');
    }
    _defaultDriverName = name;
  }

  @override
  QueueDriver getDefaultDriver() {
    if (_defaultDriverName == null ||
        !_drivers.containsKey(_defaultDriverName)) {
      throw QueueException('No default driver set or default driver not found');
    }
    return _drivers[_defaultDriverName]!;
  }

  @override
  String getDefaultDriverName() {
    if (_defaultDriverName == null) {
      throw QueueException('No default driver set');
    }
    return _defaultDriverName!;
  }

  @override
  void removeDriver(String name) {
    unregister(name);
  }

  /// Clears all registered drivers.
  void clear() {
    _drivers.clear();
    _defaultDriverName = null;
  }
}
