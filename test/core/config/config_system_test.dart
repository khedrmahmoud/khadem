import 'dart:io';
import 'package:test/test.dart';
import 'package:khadem/src/core/config/config_system.dart';
import 'package:khadem/src/support/exceptions/config_exception.dart';

void main() {
  late Directory tempDir;
  late String configPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_test_');
    configPath = tempDir.path;

    // Create base config
    final appConfig = Directory('${configPath}/config')
      ..createSync(recursive: true);
    File('${appConfig.path}/app.json')
      ..createSync()
      ..writeAsStringSync('''
        {
          "name": "Khadem",
          "version": "1.0.0",
          "debug": false,
          "database": {
            "host": "localhost",
            "port": 3306
          }
        }
      ''');

    // Create environment-specific config
    final devConfig = Directory('${configPath}/config/development')
      ..createSync(recursive: true);
    File('${devConfig.path}/app.json')
      ..createSync()
      ..writeAsStringSync('''
        {
          "debug": true,
          "database": {
            "port": 3307
          }
        }
      ''');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ConfigSystem', () {
    test('should load base configuration', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'production',
        useCache: false,
      );

      expect(config.get<String>('app.name'), equals('Khadem'));
      expect(config.get<String>('app.version'), equals('1.0.0'));
      expect(config.get<bool>('app.debug'), equals(false));
      expect(config.get<int>('app.database.port'), equals(3306));
    });

    test('should merge environment-specific configuration', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'development',
        useCache: false,
      );

      expect(config.get<String>('app.name'), equals('Khadem'));
      expect(config.get<bool>('app.debug'), equals(true));
      expect(config.get<int>('app.database.port'), equals(3307));
    });

    test('should return default value for non-existent key', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'production',
        useCache: false,
      );

      expect(config.get<String>('app.non_existent', 'default'),
          equals('default'));
    });

    test('should throw ConfigException for invalid config directory', () {
      expect(
        () => ConfigSystem(
          configPath: '${configPath}/non_existent',
          environment: 'production',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('should set and get runtime configuration values', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'production',
        useCache: false,
      );

      config.set('app.runtime_key', 'runtime_value');
      expect(config.get<String>('app.runtime_key'), equals('runtime_value'));
    });

    test('should handle nested configuration values', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'production',
        useCache: false,
      );

      config.set('app.nested.key1.key2', 'nested_value');
      expect(config.get<String>('app.nested.key1.key2'),
          equals('nested_value'));
    });

    test('should check if configuration key exists', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'production',
        useCache: false,
      );

      expect(config.has('app.name'), isTrue);
      expect(config.has('app.non_existent'), isFalse);
    });

    test('should handle environment change', () {
      final config = ConfigSystem(
        configPath: '${configPath}/config',
        environment: 'production',
        useCache: false,
      );

      expect(config.get<bool>('app.debug'), isFalse);

      config.setEnvironment('development');
      expect(config.get<bool>('app.debug'), isTrue);
    });
  });
}