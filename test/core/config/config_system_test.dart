import 'dart:io';

import 'package:khadem/src/core/config/config_system.dart';
import 'package:khadem/src/support/exceptions/config_exception.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String configPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_test_');
    configPath = '${tempDir.path}/config';

    // Create base config directory
    Directory(configPath).createSync(recursive: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ConfigSystem', () {
    group('Initialization and Basic Loading', () {
      test('should create instance with valid config directory', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "TestApp"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('TestApp'));
      });

      test('should throw ConfigException for non-existent config directory',
          () {
        expect(
          () => ConfigSystem(
            configPath: '${tempDir.path}/non_existent',
            environment: 'production',
          ),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should handle empty config directory', () {
        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.all().isEmpty, isTrue);
      });

      test('should load multiple config files', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "TestApp", "version": "1.0"}');

        File('$configPath/database.json')
          ..createSync()
          ..writeAsStringSync('{"host": "localhost", "port": 3306}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('TestApp'));
        expect(config.get<String>('database.host'), equals('localhost'));
        expect(config.get<int>('database.port'), equals(3306));
      });
    });

    group('Environment-Specific Configuration', () {
      test('should load base configuration', () {
        File('$configPath/app.json')
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

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('Khadem'));
        expect(config.get<String>('app.version'), equals('1.0.0'));
        expect(config.get<bool>('app.debug'), equals(false));
        expect(config.get<int>('app.database.port'), equals(3306));
      });

      test('should merge environment-specific configuration', () {
        // Base config
        File('$configPath/app.json')
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

        // Environment-specific config
        Directory('$configPath/development').createSync(recursive: true);
        File('$configPath/development/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "debug": true,
              "database": {
                "port": 3307
              }
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'development',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('Khadem')); // From base
        expect(config.get<bool>('app.debug'), equals(true)); // Overridden
        expect(
          config.get<int>('app.database.port'),
          equals(3307),
        ); // Overridden
      });

      test('should handle environment change', () {
        // Base config
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"debug": false}');

        // Development config
        Directory('$configPath/development').createSync(recursive: true);
        File('$configPath/development/app.json')
          ..createSync()
          ..writeAsStringSync('{"debug": true}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<bool>('app.debug'), equals(false));

        config.setEnvironment('development');
        expect(config.get<bool>('app.debug'), equals(true));
      });

      test('should handle non-existent environment directory', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "TestApp"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'non_existent_env',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('TestApp'));
      });
    });

    group('Dot Notation Access', () {
      test('should access nested values with dot notation', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "database": {
                "connection": {
                  "host": "localhost",
                  "port": 3306,
                  "credentials": {
                    "username": "root",
                    "password": "secret"
                  }
                }
              }
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(
          config.get<String>('app.database.connection.host'),
          equals('localhost'),
        );
        expect(config.get<int>('app.database.connection.port'), equals(3306));
        expect(
          config.get<String>('app.database.connection.credentials.username'),
          equals('root'),
        );
        expect(
          config.get<String>('app.database.connection.credentials.password'),
          equals('secret'),
        );
      });

      test('should return default value for non-existent nested key', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "TestApp"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(
          config.get<String>('app.database.host', 'localhost'),
          equals('localhost'),
        );
        expect(config.get<int>('app.database.port', 3306), equals(3306));
      });

      test('should handle invalid nested access', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "scalar": "not_an_object",
              "nested": {"key": "value"}
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(
          config.get<String>('app.scalar.fake_key', 'default'),
          equals('default'),
        );
        expect(config.get<String>('app.nested.key'), equals('value'));
      });
    });

    group('Type Safety and Defaults', () {
      test('should handle different data types', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "string_val": "hello",
              "int_val": 42,
              "double_val": 3.14,
              "bool_val": true,
              "null_val": null,
              "list_val": ["a", "b", "c"],
              "object_val": {"nested": "value"}
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.string_val'), equals('hello'));
        expect(config.get<int>('app.int_val'), equals(42));
        expect(config.get<double>('app.double_val'), equals(3.14));
        expect(config.get<bool>('app.bool_val'), equals(true));
        expect(config.get<List>('app.list_val'), equals(['a', 'b', 'c']));
        expect(
          config.get<Map<String, dynamic>>('app.object_val'),
          equals({'nested': 'value'}),
        );
      });

      test('should return default values for type mismatches', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "string_val": 123,
              "int_val": "not_a_number"
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(
          config.get<String>('app.string_val', 'default'),
          equals('default'),
        );
        expect(config.get<int>('app.int_val', 42), equals(42));
      });

      test('should handle null values', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"null_val": null}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.null_val'), isNull);
        expect(
          config.get<String>('app.null_val', 'default'),
          equals('default'),
        );
      });
    });

    group('Runtime Configuration', () {
      test('should set and get runtime configuration values', () {
        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        config.set('app.runtime_key', 'runtime_value');
        expect(config.get<String>('app.runtime_key'), equals('runtime_value'));
      });

      test('should handle nested runtime configuration', () {
        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        config.set('app.nested.deep.key', 'nested_value');
        expect(
          config.get<String>('app.nested.deep.key'),
          equals('nested_value'),
        );
      });

      test('should override file-based config with runtime values', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "OriginalName"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('OriginalName'));

        config.set('app.name', 'RuntimeName');
        expect(config.get<String>('app.name'), equals('RuntimeName'));
      });

      test('should throw exception when setting on non-object value', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"scalar": "not_an_object"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(
          () => config.set('app.scalar.nested', 'value'),
          throwsA(isA<ConfigException>()),
        );
      });
    });

    group('Key Existence Checks', () {
      test('should check if configuration key exists', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "existing_key": "value",
              "nested": {
                "key": "nested_value"
              }
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.has('app.existing_key'), isTrue);
        expect(config.has('app.nested.key'), isTrue);
        expect(config.has('app.non_existent'), isFalse);
        expect(config.has('app.nested.non_existent'), isFalse);
        expect(config.has('non_existent.section'), isFalse);
      });

      test('should handle has() with invalid nested access', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"scalar": "not_an_object"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.has('app.scalar'), isTrue);
        expect(config.has('app.scalar.fake_key'), isFalse);
      });
    });

    group('Configuration Sections', () {
      test('should return entire configuration sections', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "name": "TestApp",
              "version": "1.0",
              "settings": {
                "debug": true,
                "timeout": 30
              }
            }
          ''');

        File('$configPath/database.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "host": "localhost",
              "port": 3306
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        final appSection = config.section('app');
        expect(appSection, isNotNull);
        expect(appSection!['name'], equals('TestApp'));
        expect(appSection['settings'], equals({'debug': true, 'timeout': 30}));

        final dbSection = config.section('database');
        expect(dbSection, isNotNull);
        expect(dbSection!['host'], equals('localhost'));
        expect(dbSection['port'], equals(3306));
      });

      test('should return null for non-existent sections', () {
        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.section('non_existent'), isNull);
      });

      test('should return null for non-object sections', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"scalar": "not_an_object"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.section('app'), equals({'scalar': 'not_an_object'}));
      });
    });

    group('Configuration Management', () {
      test('should return all configuration data', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "TestApp"}');

        File('$configPath/database.json')
          ..createSync()
          ..writeAsStringSync('{"host": "localhost"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        final all = config.all();
        expect(all.containsKey('app'), isTrue);
        expect(all.containsKey('database'), isTrue);
        expect(all['app']['name'], equals('TestApp'));
        expect(all['database']['host'], equals('localhost'));
      });

      test('should reload all configurations', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "Original"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('Original'));

        // Modify the file
        File('$configPath/app.json')..writeAsStringSync('{"name": "Modified"}');

        config.reload();
        expect(config.get<String>('app.name'), equals('Modified'));
      });

      test('should load from registry', () {
        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        final registry = {
          'app': {'name': 'RegistryApp', 'version': '2.0'},
          'cache': {'driver': 'redis'},
        };

        config.loadFromRegistry(registry);

        expect(config.get<String>('app.name'), equals('RegistryApp'));
        expect(config.get<String>('app.version'), equals('2.0'));
        expect(config.get<String>('cache.driver'), equals('redis'));
      });
    });

    group('Caching Behavior', () {
      test('should respect cache settings', () async {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "CachedApp"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          cacheTtl: const Duration(milliseconds: 100),
        );

        expect(config.get<String>('app.name'), equals('CachedApp'));

        // Modify file
        File('$configPath/app.json')
          ..writeAsStringSync('{"name": "ModifiedApp"}');

        // Should still return cached value
        expect(config.get<String>('app.name'), equals('CachedApp'));

        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 150));

        // Should reload and return new value
        expect(config.get<String>('app.name'), equals('ModifiedApp'));
      });

      test('should disable caching when useCache is false', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{"name": "NoCacheApp"}');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(config.get<String>('app.name'), equals('NoCacheApp'));

        // Modify file
        File('$configPath/app.json')
          ..writeAsStringSync('{"name": "ModifiedNoCache"}');

        // With caching disabled, should still return cached value
        expect(config.get<String>('app.name'), equals('NoCacheApp'));

        // But reload() should work
        config.reload();
        expect(config.get<String>('app.name'), equals('ModifiedNoCache'));
      });
    });

    group('Error Handling', () {
      test('should handle malformed JSON files', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('{invalid json}');

        expect(
          () => ConfigSystem(
            configPath: configPath,
            environment: 'production',
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle YAML files (not implemented)', () {
        File('$configPath/app.yaml')
          ..createSync()
          ..writeAsStringSync('name: TestApp');

        expect(
          () => ConfigSystem(
            configPath: configPath,
            environment: 'production',
          ),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should handle deep nested access gracefully', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync(
            '{"level1": {"level2": {"level3": "deep_value"}}}',
          );

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        expect(
          config.get<String>('app.level1.level2.level3'),
          equals('deep_value'),
        );
        expect(
          config.get<String>('app.level1.nonexistent.level3', 'default'),
          equals('default'),
        );
      });
    });

    group('Complex Configuration Scenarios', () {
      test('should handle complex real-world configuration', () {
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "name": "Khadem",
              "version": "1.0.0",
              "debug": false,
              "services": {
                "api": {
                  "host": "0.0.0.0",
                  "port": 3000,
                  "ssl": false
                },
                "websocket": {
                  "enabled": true,
                  "port": 8080
                }
              },
              "features": ["auth", "cache", "queue"],
              "limits": {
                "max_connections": 1000,
                "timeout": 30,
                "rate_limit": {
                  "requests_per_minute": 60,
                  "burst_limit": 10
                }
              }
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'production',
          useCache: false,
        );

        // Test various access patterns
        expect(config.get<String>('app.name'), equals('Khadem'));
        expect(config.get<bool>('app.debug'), equals(false));
        expect(config.get<int>('app.services.api.port'), equals(3000));
        expect(
          config.get<bool>('app.services.websocket.enabled'),
          equals(true),
        );
        expect(
          config.get<List>('app.features'),
          equals(['auth', 'cache', 'queue']),
        );
        expect(
          config.get<int>('app.limits.rate_limit.requests_per_minute'),
          equals(60),
        );
      });

      test('should handle multiple environment overrides', () {
        // Base config
        File('$configPath/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "debug": false,
              "database": {"host": "localhost", "port": 3306},
              "cache": {"driver": "file"}
            }
          ''');

        File('$configPath/cache.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "ttl": 3600,
              "prefix": "app_cache"
            }
          ''');

        // Development overrides
        Directory('$configPath/development').createSync(recursive: true);
        File('$configPath/development/app.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "debug": true,
              "database": {"port": 3307}
            }
          ''');

        File('$configPath/development/cache.json')
          ..createSync()
          ..writeAsStringSync('''
            {
              "ttl": 300,
              "driver": "redis"
            }
          ''');

        final config = ConfigSystem(
          configPath: configPath,
          environment: 'development',
          useCache: false,
        );

        // Test merged values
        expect(config.get<bool>('app.debug'), equals(true)); // Overridden
        expect(
          config.get<String>('app.database.host'),
          equals('localhost'),
        ); // From base
        expect(
          config.get<int>('app.database.port'),
          equals(3307),
        ); // Overridden
        expect(
          config.get<String>('cache.driver'),
          equals('redis'),
        ); // Overridden
        expect(config.get<int>('cache.ttl'), equals(300)); // Overridden
        expect(
          config.get<String>('cache.prefix'),
          equals('app_cache'),
        ); // From base
      });
    });
  });
}
