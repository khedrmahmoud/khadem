import 'package:khadem/src/support/exceptions/cache_exceptions.dart';

import '../../../contracts/cache/cache_driver.dart';
import '../../../contracts/cache/cache_driver_registry.dart';

/// Implementation of cache driver registry.
/// Manages the registration and retrieval of cache drivers.
class CacheDriverRegistry implements ICacheDriverRegistry {
  final Map<String, CacheDriver> _drivers = {};
  late CacheDriver _defaultDriver;

  @override
  void registerDriver(String name, CacheDriver driver) {
    if (name.isEmpty) {
      throw CacheException('Cache driver name cannot be empty');
    }
    if (_drivers.containsKey(name)) {
      throw CacheException('Cache driver "$name" is already registered');
    }

    _drivers[name] = driver;

    // Set as default if it's the first driver
    if (_drivers.length == 1) {
      _defaultDriver = driver;
    }
  }

  @override
  CacheDriver? getDriver(String name) {
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
      throw CacheException('Cache driver "$name" not registered');
    }
    _defaultDriver = _drivers[name]!;
  }

  @override
  CacheDriver getDefaultDriver() {
    if (_drivers.isEmpty) {
      throw CacheException('No cache drivers registered');
    }
    return _defaultDriver;
  }

  @override
  String getDefaultDriverName() {
    if (_drivers.isEmpty) {
      throw CacheException('No cache drivers registered');
    }
    return _drivers.entries.firstWhere((e) => e.value == _defaultDriver).key;
  }

  @override
  void removeDriver(String name) {
    if (!_drivers.containsKey(name)) {
      throw CacheException('Cache driver "$name" not registered');
    }

    final driver = _drivers[name]!;
    if (driver == _defaultDriver) {
      throw CacheException('Cannot remove the default cache driver');
    }

    _drivers.remove(name);
  }
}
