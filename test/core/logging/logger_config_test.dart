import 'package:khadem/khadem.dart';
import 'package:test/test.dart';

class MockConfig implements ConfigInterface {
  final Map<String, dynamic> _config;

  MockConfig(this._config);

  @override
  T? get<T>(String key, [T? defaultValue]) {
    final parts = key.split('.');
    dynamic current = _config;

    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return defaultValue;
      }
    }

    return current as T? ?? defaultValue;
  }

  @override
  T getOrFail<T>(String key) {
    final value = get<T>(key);
    if (value == null) throw Exception('Config key $key not found');
    return value;
  }

  @override
  Map<String, dynamic>? section(String key) {
    return get<Map<String, dynamic>>(key);
  }

  @override
  void set(String key, dynamic value) {}

  @override
  void push(String key, dynamic value) {}

  @override
  void pop(String key) {}

  @override
  bool has(String key) => get(key) != null;

  @override
  Map<String, dynamic> all() => _config;

  @override
  void reload() {}

  @override
  void loadFromRegistry(Map<String, Map<String, dynamic>> registry) {}
}

void main() {
  group('Logger Configuration', () {
    test('should load channels from new config structure', () {
      final configMap = {
        'logging': {
          'default': 'stack',
          'channels': {
            'stack': {
              'driver': 'stack',
              'channels': ['daily', 'console'],
            },
            'daily': {
              'driver': 'daily',
              'path': 'storage/logs/khadem.log',
              'level': 'debug',
              'days': 14,
            },
            'console': {'driver': 'console', 'level': 'debug', 'colorize': true},
          },
        },
      };

      final config = MockConfig(configMap);
      final logger = Logger();
      logger.loadFromConfig(config);

      expect(logger.defaultChannel, equals('stack'));
    });

    test('should fallback to legacy config structure', () {
      final configMap = {
        'logging': {
          'default': 'app',
          'handlers': {
            'file': {
              'enabled': true,
              'path': 'storage/logs/app.log',
              'level': 'info',
            },
            'console': {'enabled': true, 'level': 'debug'},
          },
        },
      };

      final config = MockConfig(configMap);
      final logger = Logger();
      logger.loadFromConfig(config);

      expect(logger.defaultChannel, equals('app'));
    });
  });
}
