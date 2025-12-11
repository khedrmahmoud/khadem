import 'package:khadem/src/core/config/config_system.dart';
import 'package:khadem/src/core/config/env_system.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('ConfigSystem Enhancements', () {
    late ConfigSystem config;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('config_test_');
      File('${tempDir.path}/app.json').writeAsStringSync('{"name": "TestApp", "debug": true}');
      
      config = ConfigSystem(
        configPath: tempDir.path,
        environment: 'testing',
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('getOrFail should return value if exists', () {
      expect(config.getOrFail<String>('app.name'), equals('TestApp'));
    });

    test('getOrFail should throw if key missing', () {
      expect(
        () => config.getOrFail<String>('app.missing'),
        throwsA(isA<Exception>()),
      );
    });

    test('push should override value temporarily', () {
      config.push('app.name', 'Overridden');
      expect(config.get<String>('app.name'), equals('Overridden'));
    });

    test('pop should restore previous value', () {
      config.push('app.name', 'Overridden');
      config.pop('app.name');
      expect(config.get<String>('app.name'), equals('TestApp'));
    });

    test('push/pop should work with nested keys', () {
      config.push('app.nested.key', 'value');
      expect(config.get<String>('app.nested.key'), equals('value'));
      
      config.pop('app.nested.key');
      expect(config.get('app.nested.key'), isNull);
    });
  });

  group('EnvSystem Enhancements', () {
    late EnvSystem env;

    setUp(() {
      env = EnvSystem(useProcessEnv: false);
      env.set('TEST_BOOL_TRUE', 'true');
      env.set('TEST_BOOL_1', '1');
      env.set('TEST_BOOL_YES', 'yes');
      env.set('TEST_BOOL_ON', 'on');
      env.set('TEST_BOOL_FALSE', 'false');
      env.set('TEST_VAL', 'exists');
    });

    test('getOrFail should return value', () {
      expect(env.getOrFail('TEST_VAL'), equals('exists'));
    });

    test('getOrFail should throw if missing', () {
      expect(() => env.getOrFail('MISSING'), throwsA(isA<Exception>()));
    });

    test('getBool should handle all truthy values', () {
      expect(env.getBool('TEST_BOOL_TRUE'), isTrue);
      expect(env.getBool('TEST_BOOL_1'), isTrue);
      expect(env.getBool('TEST_BOOL_YES'), isTrue);
      expect(env.getBool('TEST_BOOL_ON'), isTrue);
    });

    test('getBool should handle falsy values', () {
      expect(env.getBool('TEST_BOOL_FALSE'), isFalse);
      expect(env.getBool('MISSING'), isFalse);
    });
  });
}
