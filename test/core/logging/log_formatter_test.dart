import 'package:khadem/khadem.dart'
    show JsonLogFormatter, LogLevel, TextLogFormatter;
import 'package:test/test.dart';

void main() {
  group('JsonLogFormatter', () {
    late JsonLogFormatter formatter;

    setUp(() {
      formatter = JsonLogFormatter();
    });

    test('should format basic message', () {
      final result = formatter.format(LogLevel.info, 'Test message');

      expect(result, contains('Test message'));
      expect(result, contains('INFO'));
      expect(result, contains('timestamp'));
    });

    test('should format message with context', () {
      final context = {'user': 'john', 'action': 'login'};
      final result =
          formatter.format(LogLevel.warning, 'User action', context: context);

      expect(result, contains('User action'));
      expect(result, contains('WARNING'));
      expect(result, contains('user'));
      expect(result, contains('john'));
      expect(result, contains('action'));
      expect(result, contains('login'));
    });

    test('should format message with stack trace', () {
      final stackTrace = StackTrace.current;
      final result = formatter.format(
        LogLevel.error,
        'Error occurred',
        stackTrace: stackTrace,
      );

      expect(result, contains('Error occurred'));
      expect(result, contains('ERROR'));
      expect(result, contains('stackTrace'));
    });

    test('should format message with custom timestamp', () {
      final timestamp = DateTime(2023, 1, 1, 12);
      final result = formatter.format(
        LogLevel.debug,
        'Debug message',
        timestamp: timestamp,
      );

      expect(result, contains('2023-01-01T12:00:00'));
    });
  });

  group('TextLogFormatter', () {
    late TextLogFormatter formatter;

    setUp(() {
      formatter = TextLogFormatter();
    });

    test('should format basic message with defaults', () {
      final result = formatter.format(LogLevel.info, 'Test message');

      expect(result, contains('[INFO] Test message'));
      expect(result, contains('['));
      expect(result, contains(']'));
    });

    test('should format message without timestamp', () {
      final formatter = TextLogFormatter(includeTimestamp: false);
      final result = formatter.format(LogLevel.warning, 'Warning message');

      expect(result, contains('[WARNING] Warning message'));
      expect(result, isNot(contains('T'))); // ISO timestamp contains 'T'
    });

    test('should format message without level', () {
      final formatter = TextLogFormatter(includeLevel: false);
      final result = formatter.format(LogLevel.error, 'Error message');

      expect(result, contains('Error message'));
      expect(result, isNot(contains('[ERROR]')));
    });

    test('should format message with context', () {
      final context = {'key': 'value', 'number': 42};
      final result =
          formatter.format(LogLevel.debug, 'Debug message', context: context);

      expect(result, contains('[DEBUG] Debug message'));
      expect(result, contains('Context:'));
      expect(result, contains('key'));
      expect(result, contains('value'));
      expect(result, contains('number'));
      expect(result, contains('42'));
    });

    test('should format message with stack trace', () {
      final stackTrace = StackTrace.current;
      final result = formatter.format(
        LogLevel.critical,
        'Critical error',
        stackTrace: stackTrace,
      );

      expect(result, contains('[CRITICAL] Critical error'));
      expect(result, contains('Stack Trace:'));
    });

    test('should format message with custom timestamp', () {
      final timestamp = DateTime(2023, 1, 1, 12);
      final result =
          formatter.format(LogLevel.info, 'Test message', timestamp: timestamp);

      expect(result, contains('2023-01-01T12:00:00'));
    });

    test('should handle empty context', () {
      final result =
          formatter.format(LogLevel.info, 'Test message', context: {});

      expect(result, contains('[INFO] Test message'));
      expect(result, isNot(contains('Context:')));
    });

    test('should handle null context', () {
      final result = formatter.format(LogLevel.info, 'Test message');

      expect(result, contains('[INFO] Test message'));
      expect(result, isNot(contains('Context:')));
    });
  });
}
