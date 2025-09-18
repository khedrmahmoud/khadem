import 'dart:io';

import 'package:khadem/src/core/storage/local_disk.dart';
import 'package:khadem/src/core/storage/storage_manager.dart';
import 'package:khadem/src/support/exceptions/not_found_exception.dart';
import 'package:khadem/src/support/exceptions/storage_exception.dart';
import 'package:test/test.dart';

void main() {
  group('StorageManager', () {
    late StorageManager storageManager;
    late LocalDisk localDisk;

    setUp(() {
      storageManager = StorageManager();
      localDisk = LocalDisk(basePath: Directory.systemTemp.path + '/test_storage');
    });

    test('should initialize with default local driver', () {
      expect(storageManager.defaultDisk, equals('local'));
      expect(storageManager.diskCount, equals(0)); // No disks registered yet
      expect(storageManager.driverCount, equals(1)); // local driver registered
    });

    test('should register disk successfully', () {
      storageManager.registerDisk('test', localDisk);

      expect(storageManager.hasDisk('test'), isTrue);
      expect(storageManager.diskCount, equals(1));
    });

    test('should throw when registering disk with empty name', () {
      expect(() => storageManager.registerDisk('', localDisk),
             throwsA(isA<StorageException>()),);
    });

    test('should get disk by name', () {
      storageManager.registerDisk('test', localDisk);

      final disk = storageManager.disk('test');
      expect(disk, equals(localDisk));
    });

    test('should get default disk when no name provided', () {
      storageManager.registerDisk('local', localDisk);

      final disk = storageManager.disk();
      expect(disk, equals(localDisk));
    });

    test('should throw when getting non-existent disk', () {
      expect(() => storageManager.disk('nonexistent'),
             throwsA(isA<NotFoundException>()),);
    });

    test('should remove disk successfully', () {
      storageManager.registerDisk('test', localDisk);
      expect(storageManager.hasDisk('test'), isTrue);

      storageManager.removeDisk('test');
      expect(storageManager.hasDisk('test'), isFalse);
    });

    test('should throw when removing non-existent disk', () {
      expect(() => storageManager.removeDisk('nonexistent'),
             throwsA(isA<NotFoundException>()),);
    });

    test('should set default disk successfully', () {
      storageManager.registerDisk('test', localDisk);
      storageManager.setDefaultDisk('test');

      expect(storageManager.defaultDisk, equals('test'));
    });

    test('should throw when setting non-existent disk as default', () {
      expect(() => storageManager.setDefaultDisk('nonexistent'),
             throwsA(isA<NotFoundException>()),);
    });

    test('should register driver successfully', () {
      storageManager.registerDriver('custom', (options) => LocalDisk(basePath: './custom'));

      expect(storageManager.driverCount, equals(2)); // local + custom
    });

    test('should throw when registering driver with empty name', () {
      expect(() => storageManager.registerDriver('', (options) => LocalDisk(basePath: './test')),
             throwsA(isA<StorageException>()),);
    });

    test('should load configuration successfully', () {
      final config = {
        'default': 'test',
        'disks': {
          'test': {
            'driver': 'local',
            'root': './test-storage',
          },
        },
      };

      storageManager.fromConfig(config);

      expect(storageManager.defaultDisk, equals('test'));
      expect(storageManager.hasDisk('test'), isTrue);
    });

    test('should throw when loading config with missing driver', () {
      final config = {
        'disks': {
          'test': {
            'root': './test-storage',
            // missing 'driver' key
          },
        },
      };

      expect(() => storageManager.fromConfig(config),
             throwsA(isA<StorageException>()),);
    });

    test('should throw when loading config with unsupported driver', () {
      final config = {
        'disks': {
          'test': {
            'driver': 'unsupported',
            'root': './test-storage',
          },
        },
      };

      expect(() => storageManager.fromConfig(config),
             throwsA(isA<NotFoundException>()),);
    });

    test('should flush all disks', () {
      storageManager.registerDisk('test1', localDisk);
      storageManager.registerDisk('test2', LocalDisk(basePath: './test2'));

      expect(storageManager.diskCount, equals(2));

      storageManager.flush();
      expect(storageManager.diskCount, equals(0));
    });

    test('should get disk names', () {
      storageManager.registerDisk('test1', localDisk);
      storageManager.registerDisk('test2', LocalDisk(basePath: './test2'));

      final names = storageManager.diskNames;
      expect(names, contains('test1'));
      expect(names, contains('test2'));
      expect(names.length, equals(2));
    });

    test('should handle configuration without disks', () {
      final config = {
        'default': 'local',
      };

      storageManager.fromConfig(config);
      expect(storageManager.defaultDisk, equals('local'));
    });

    test('should handle configuration without default', () {
      final config = {
        'disks': {
          'local': {
            'driver': 'local',
            'root': './storage',
          },
        },
      };

      storageManager.fromConfig(config);
      expect(storageManager.defaultDisk, equals('local')); // should keep original default
    });
  });
}
