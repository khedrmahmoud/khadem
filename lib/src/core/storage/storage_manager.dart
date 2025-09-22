import '../../contracts/storage/storage_disk.dart';
import '../../support/exceptions/not_found_exception.dart';
import '../../support/exceptions/storage_exception.dart';
import 'local_disk.dart';

typedef StorageDriverFactory = StorageDisk Function(
  Map<String, dynamic> options,
);

class StorageManager {
  final Map<String, StorageDisk> _disks;
  final Map<String, StorageDriverFactory> _drivers;
  String _defaultDisk;

  StorageManager({
    String defaultDisk = 'local',
    Map<String, StorageDisk>? initialDisks,
    Map<String, StorageDriverFactory>? customDrivers,
  })  : _disks = initialDisks ?? {},
        _drivers = customDrivers ?? {},
        _defaultDisk = defaultDisk {
    _registerDefaultDrivers();
  }

  void _registerDefaultDrivers() {
    // Register built-in local driver
    registerDriver('local', (options) {
      final root = options['root'] ?? './storage';
      return LocalDisk(basePath: root as String);
    });
  }

  /// Registers a custom storage driver.
  void registerDriver(String name, StorageDriverFactory factory) {
    if (name.isEmpty) {
      throw StorageException('Driver name cannot be empty');
    }
    _drivers[name] = factory;
  }

  /// Loads disks dynamically from a config map.
  void fromConfig(Map<String, dynamic> config) {
    if (config.containsKey('default') && config['default'] is String) {
      _defaultDisk = config['default'] as String;
    }

    final disks = config['disks'] as Map<String, dynamic>? ?? {};

    for (final entry in disks.entries) {
      final name = entry.key;
      final options = entry.value as Map<String, dynamic>;

      if (!options.containsKey('driver')) {
        throw StorageException('Driver not specified for disk "$name"');
      }

      final driver = options['driver'] as String;
      final factory = _drivers[driver];

      if (factory == null) {
        throw NotFoundException('Unsupported storage driver "$driver"');
      }

      final disk = factory(options);
      registerDisk(name, disk);
    }
  }

  /// Returns a disk instance by name or uses the default.
  StorageDisk disk([String? name]) {
    final key = name ?? _defaultDisk;
    final disk = _disks[key];

    if (disk == null) {
      throw NotFoundException('Storage disk "$key" is not defined.');
    }

    return disk;
  }

  /// Registers a disk manually at runtime.
  void registerDisk(String name, StorageDisk disk) {
    if (name.isEmpty) {
      throw StorageException('Disk name cannot be empty');
    }
    _disks[name] = disk;
  }

  /// Checks if a disk is registered
  bool hasDisk(String name) {
    return _disks.containsKey(name);
  }

  /// Removes a disk from the registry
  void removeDisk(String name) {
    if (!_disks.containsKey(name)) {
      throw NotFoundException('Disk "$name" is not registered');
    }
    _disks.remove(name);
  }

  /// Clears all registered disks
  void flush() {
    _disks.clear();
  }

  /// Sets the default disk
  void setDefaultDisk(String name) {
    if (!_disks.containsKey(name)) {
      throw NotFoundException('Disk "$name" is not registered.');
    }
    _defaultDisk = name;
  }

  /// Gets the current default disk name
  String get defaultDisk => _defaultDisk;

  /// Gets all registered disk names
  List<String> get diskNames => _disks.keys.toList();

  /// Gets the number of registered disks
  int get diskCount => _disks.length;

  /// Gets the number of registered drivers
  int get driverCount => _drivers.length;
}
