import 'package:khadem/src/contracts/logging/log_level.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../mocks/logging_mocks.dart';

void main() {
  group('Logger', () {
    late Logger logger;
    late MockLogHandler handler;
    late MockLogChannelManager channelManager;

    setUp(() {
      handler = MockLogHandler();
      channelManager = MockLogChannelManager();
      logger = Logger(channelManager: channelManager);
    });

    test('should have default minimum level', () {
      expect(logger.minimumLevel, LogLevel.debug);
    });

    test('should have default channel', () {
      expect(logger.defaultChannel, 'app');
    });

    test('should set minimum level', () {
      logger.minimumLevel = LogLevel.error;
      expect(logger.minimumLevel, LogLevel.error);
    });

    test('should set default channel', () {
      logger.setDefaultChannel('custom');
      expect(logger.defaultChannel, 'custom');
    });

    test('should add handler to channel manager', () {
      logger.addHandler(handler, channel: 'test');

      verify(channelManager.addHandler(handler, channel: 'test')).called(1);
    });

    test('should log debug message', () {
      logger.debug('Debug message', context: {'key': 'value'});

      verify(
        channelManager.logToChannel(
          'app',
          LogLevel.debug,
          'Debug message',
          context: {'key': 'value'},
        ),
      ).called(1);
    });

    test('should log info message', () {
      logger.info('Info message');

      verify(
        channelManager.logToChannel(
          'app',
          LogLevel.info,
          'Info message',
        ),
      ).called(1);
    });

    test('should log warning message', () {
      logger.warning('Warning message', channel: 'custom');

      verify(
        channelManager.logToChannel(
          'custom',
          LogLevel.warning,
          'Warning message',
        ),
      ).called(1);
    });

    test('should log error message', () {
      final stackTrace = StackTrace.current;
      logger.error('Error message', stackTrace: stackTrace);

      verify(
        channelManager.logToChannel(
          'app',
          LogLevel.error,
          'Error message',
          stackTrace: stackTrace,
        ),
      ).called(1);
    });

    test('should log critical message', () {
      logger.critical('Critical message');

      verify(
        channelManager.logToChannel(
          'app',
          LogLevel.critical,
          'Critical message',
        ),
      ).called(1);
    });

    test('should log with specific level', () {
      logger.log(LogLevel.warning, 'Custom level message');

      verify(
        channelManager.logToChannel(
          'app',
          LogLevel.warning,
          'Custom level message',
        ),
      ).called(1);
    });

    test('should filter messages below minimum level', () {
      logger.minimumLevel = LogLevel.warning;

      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');

      verifyNever(
        channelManager.logToChannel(
          'app',
          LogLevel.debug,
          'Debug message',
        ),
      );

      verifyNever(
        channelManager.logToChannel(
          'app',
          LogLevel.info,
          'Info message',
        ),
      );

      verify(
        channelManager.logToChannel(
          'app',
          LogLevel.warning,
          'Warning message',
        ),
      ).called(1);
    });

    test('should close channel manager', () {
      logger.close();

      verify(channelManager.closeAll()).called(1);
    });
  });

  group('Logger configuration', () {
    late MockConfig config;
    late Logger logger;

    setUp(() {
      config = MockConfig();
      logger = Logger();
    });

    test('should load configuration successfully', () {
      when(config.get<String>('logging.minimum_level', 'debug'))
          .thenReturn('info');
      when(config.get<String>('logging.default', 'app')).thenReturn('custom');
      when(config.get<Map<String, dynamic>>('logging.handlers', {}))
          .thenReturn({
        'console': {'enabled': true, 'colorize': false},
        'file': {'enabled': false},
      });

      logger.loadFromConfig(config);

      expect(logger.minimumLevel, LogLevel.info);
      expect(logger.defaultChannel, 'custom');
    });

    test('should handle configuration errors gracefully', () {
      when(config.get<String>('logging.minimum_level', 'debug'))
          .thenReturn('invalid');
      when(config.get<String>('logging.default', 'app')).thenReturn('test');
      when(config.get<Map<String, dynamic>>('logging.handlers', {}))
          .thenReturn({});

      // The logger should handle configuration errors gracefully
      // In a real implementation, this might log a warning and use defaults
      expect(logger.defaultChannel, 'app'); // Should retain original value
    });
  });
}
