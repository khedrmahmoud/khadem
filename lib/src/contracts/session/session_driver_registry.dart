import 'session_interfaces.dart';

/// Session driver registry implementation.
/// Manages registration and retrieval of session storage drivers.
class SessionDriverRegistry implements ISessionDriverRegistry {
  final Map<String, SessionDriver> _drivers = {};
  String? _defaultDriverName;

  @override
  void registerDriver(String name, SessionDriver driver) {
    if (name.isEmpty) {
      throw ArgumentError('Driver name cannot be empty');
    }
    if (_drivers.containsKey(name)) {
      throw StateError('Driver "$name" is already registered');
    }
    _drivers[name] = driver;

    // Set as default if it's the first driver
    _defaultDriverName ??= name;
  }

  @override
  SessionDriver? getDriver(String name) {
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
    if (!hasDriver(name)) {
      throw StateError('Driver "$name" is not registered');
    }
    _defaultDriverName = name;
  }

  @override
  SessionDriver getDefaultDriver() {
    if (_defaultDriverName == null) {
      throw StateError('No default driver set');
    }
    return _drivers[_defaultDriverName]!;
  }

  @override
  String getDefaultDriverName() {
    if (_defaultDriverName == null) {
      throw StateError('No default driver set');
    }
    return _defaultDriverName!;
  }

  @override
  void removeDriver(String name) {
    if (!hasDriver(name)) {
      throw StateError('Driver "$name" is not registered');
    }
    if (_defaultDriverName == name) {
      throw StateError('Cannot remove the default driver "$name"');
    }
    _drivers.remove(name);
  }
}