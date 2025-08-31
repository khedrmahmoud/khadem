import 'package:test/test.dart';

import '../../../lib/src/core/logging/log_level.dart';

void main() {
  group('LogLevel', () {
    test('should have correct values', () {
      expect(LogLevel.debug.value, 0);
      expect(LogLevel.info.value, 1);
      expect(LogLevel.warning.value, 2);
      expect(LogLevel.error.value, 3);
      expect(LogLevel.critical.value, 4);
    });

    test('isAtLeast should work correctly', () {
      expect(LogLevel.debug.isAtLeast(LogLevel.debug), isTrue);
      expect(LogLevel.debug.isAtLeast(LogLevel.info), isFalse);
      expect(LogLevel.info.isAtLeast(LogLevel.debug), isTrue);
      expect(LogLevel.error.isAtLeast(LogLevel.warning), isTrue);
      expect(LogLevel.warning.isAtLeast(LogLevel.error), isFalse);
      expect(LogLevel.critical.isAtLeast(LogLevel.debug), isTrue);
    });

    test('fromString should parse correctly', () {
      expect(LogLevelExtension.fromString('debug'), LogLevel.debug);
      expect(LogLevelExtension.fromString('DEBUG'), LogLevel.debug);
      expect(LogLevelExtension.fromString('info'), LogLevel.info);
      expect(LogLevelExtension.fromString('INFO'), LogLevel.info);
      expect(LogLevelExtension.fromString('warning'), LogLevel.warning);
      expect(LogLevelExtension.fromString('WARNING'), LogLevel.warning);
      expect(LogLevelExtension.fromString('error'), LogLevel.error);
      expect(LogLevelExtension.fromString('ERROR'), LogLevel.error);
      expect(LogLevelExtension.fromString('critical'), LogLevel.critical);
      expect(LogLevelExtension.fromString('CRITICAL'), LogLevel.critical);
    });

    test('fromString should throw on invalid input', () {
      expect(() => LogLevelExtension.fromString('invalid'), throwsArgumentError);
      expect(() => LogLevelExtension.fromString(''), throwsArgumentError);
      expect(() => LogLevelExtension.fromString('trace'), throwsArgumentError);
    });

    test('name should return correct string', () {
      expect(LogLevel.debug.name, 'debug');
      expect(LogLevel.info.name, 'info');
      expect(LogLevel.warning.name, 'warning');
      expect(LogLevel.error.name, 'error');
      expect(LogLevel.critical.name, 'critical');
    });

    test('nameUpper should return uppercase string', () {
      expect(LogLevel.debug.nameUpper, 'DEBUG');
      expect(LogLevel.info.nameUpper, 'INFO');
      expect(LogLevel.warning.nameUpper, 'WARNING');
      expect(LogLevel.error.nameUpper, 'ERROR');
      expect(LogLevel.critical.nameUpper, 'CRITICAL');
    });
  });
}
