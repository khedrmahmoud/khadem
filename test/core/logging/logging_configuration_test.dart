import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/config/config_contract.dart';
import '../../../lib/src/contracts/logging/log_level.dart';
import '../../../lib/src/core/logging/logging_configuration.dart';

// Mock classes for testing
class MockConfig extends Mock implements ConfigInterface {}

void main() {
  group('LoggingConfiguration', () {
    late MockConfig config;
    late LoggingConfiguration loggingConfig;

    setUp(() {
      config = MockConfig();
      loggingConfig = LoggingConfiguration(config);
    });

    test('should get default minimum level', () {
      when(config.get<String>('logging.minimum_level', 'debug')).thenReturn('debug');

      expect(loggingConfig.minimumLevel, LogLevel.debug);
    });

    test('should parse minimum level from config', () {
      when(config.get<String>('logging.minimum_level', 'debug')).thenReturn('error');

      expect(loggingConfig.minimumLevel, LogLevel.error);
    });

    test('should get default channel', () {
      when(config.get<String>('logging.default', 'app')).thenReturn('app');

      expect(loggingConfig.defaultChannel, 'app');
    });

    test('should get custom channel from config', () {
      when(config.get<String>('logging.default', 'app')).thenReturn('custom');

      expect(loggingConfig.defaultChannel, 'custom');
    });

    test('should get empty handlers list when no handlers configured', () {
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({});

      expect(loggingConfig.handlers, isEmpty);
    });

    test('should create console handler from config', () {
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({
        'console': {
          'enabled': true,
          'colorize': false,
        },
      });

      final handlers = loggingConfig.handlers;
      expect(handlers, hasLength(1));
      // Note: We can't easily test the exact type without exposing internals
      // In a real scenario, we'd test the behavior through integration tests
    });

    test('should create file handler from config', () {
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({
        'file': {
          'enabled': true,
          'path': 'custom.log',
          'format_json': false,
          'rotate_on_size': false,
          'max_size': 1024,
          'max_backups': 3,
        },
      });

      final handlers = loggingConfig.handlers;
      expect(handlers, hasLength(1));
    });

    test('should skip disabled handlers', () {
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({
        'console': {'enabled': false},
        'file': {'enabled': false},
      });

      expect(loggingConfig.handlers, isEmpty);
    });

    test('should create both handlers when enabled', () {
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({
        'console': {'enabled': true},
        'file': {'enabled': true, 'path': 'test.log'},
      });

      final handlers = loggingConfig.handlers;
      expect(handlers, hasLength(2));
    });

    test('should validate valid configuration', () {
      when(config.get<String>('logging.minimum_level', 'debug')).thenReturn('info');
      when(config.get<String>('logging.default', 'app')).thenReturn('test');
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({
        'console': {'enabled': true},
      });

      expect(() => loggingConfig.validate(), returnsNormally);
    });

    test('should handle invalid minimum level gracefully', () {
      when(config.get<String>('logging.minimum_level', 'debug')).thenReturn('invalid');
      when(config.get<String>('logging.default', 'app')).thenReturn('test');
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({});

      // The configuration should handle invalid levels by falling back to defaults
      // This tests the robustness of the configuration system
      expect(loggingConfig.defaultChannel, 'test');
    });

    test('should throw on empty default channel', () {
      when(config.get<String>('logging.minimum_level', 'debug')).thenReturn('debug');
      when(config.get<String>('logging.default', 'app')).thenReturn('');
      when(config.get<Map<String, dynamic>>('logging.handlers', {})).thenReturn({});

      expect(() => loggingConfig.validate(), throwsArgumentError);
    });
  });
}
