import '../../contracts/storage/storage_disk.dart';
import '../../support/exceptions/not_found_exception.dart';
import 'local_disk.dart';

typedef StorageDriverFactory = StorageDisk Function(
    Map<String, dynamic> options,);

class StorageManager {
  final Map<String, StorageDisk> _disks;
  final Map<String, StorageDriverFactory> _drivers;
  String defaultDisk;

  StorageManager({
    this.defaultDisk = 'local',
    Map<String, StorageDisk>? initialDisks,
    Map<String, StorageDriverFactory>? customDrivers,
  })  : _disks = initialDisks ?? {},
        _drivers = customDrivers ?? {} {
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
    _drivers[name] = factory;
  }

  /// Loads disks dynamically from a config map.
  void fromConfig(Map<String, dynamic> config) {
    defaultDisk = config['default'] is String ? config['default'] as String : defaultDisk;

    final disks = config['disks'] as Map<String, dynamic>? ?? {};

    for (final entry in disks.entries) {
      final name = entry.key;
      final options = entry.value as Map<String, dynamic>;
      final driver = options['driver'];

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
    final key = name ?? defaultDisk;
    final disk = _disks[key];
    if (disk == null) {
      throw NotFoundException('Storage disk "$key" is not defined.');
    }
    return disk;
  }

  /// Registers a disk manually at runtime.
  void registerDisk(String name, StorageDisk disk) {
    _disks[name] = disk;
  }

  bool hasDisk(String name) => _disks.containsKey(name);

  void removeDisk(String name) {
    _disks.remove(name);
  }

  void flush() {
    _disks.clear();
  }

  void setDefaultDisk(String name) {
    if (!_disks.containsKey(name)) {
      throw NotFoundException('Disk "$name" is not registered.');
    }
    defaultDisk = name;
  }
}
