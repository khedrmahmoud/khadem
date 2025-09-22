import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/logging/log_handler.dart';
import '../../../lib/src/contracts/logging/log_level.dart';
import '../../../lib/src/core/logging/log_channel_manager.dart';

// Mock classes for testing
class MockLogHandler extends Mock implements LogHandler {}

void main() {
  group('LogChannelManager', () {
    late LogChannelManager manager;
    late MockLogHandler handler1;
    late MockLogHandler handler2;

    setUp(() {
      manager = LogChannelManager();
      handler1 = MockLogHandler();
      handler2 = MockLogHandler();
    });

    test('should start with no channels', () {
      expect(manager.channels, isEmpty);
    });

    test('should add handler to default channel', () {
      manager.addHandler(handler1);

      expect(manager.channels, contains('app'));
      expect(manager.getHandlers('app'), contains(handler1));
    });

    test('should add handler to specific channel', () {
      manager.addHandler(handler1, channel: 'custom');

      expect(manager.channels, contains('custom'));
      expect(manager.getHandlers('custom'), contains(handler1));
    });

    test('should add multiple handlers to same channel', () {
      manager.addHandler(handler1, channel: 'test');
      manager.addHandler(handler2, channel: 'test');

      expect(manager.getHandlers('test'), hasLength(2));
      expect(manager.getHandlers('test'), contains(handler1));
      expect(manager.getHandlers('test'), contains(handler2));
    });

    test('should remove handler from channel', () {
      manager.addHandler(handler1, channel: 'test');
      manager.addHandler(handler2, channel: 'test');

      manager.removeHandler(handler1, channel: 'test');

      expect(manager.getHandlers('test'), hasLength(1));
      expect(manager.getHandlers('test'), contains(handler2));
    });

    test('should clear channel', () {
      manager.addHandler(handler1, channel: 'test');
      manager.addHandler(handler2, channel: 'test');

      manager.clearChannel('test');

      expect(manager.getHandlers('test'), isEmpty);
      expect(manager.channels, isNot(contains('test')));
    });

    test('should clear all channels', () {
      manager.addHandler(handler1, channel: 'test1');
      manager.addHandler(handler2, channel: 'test2');

      manager.clearAll();

      expect(manager.channels, isEmpty);
    });

    test('should check if channel has handlers', () {
      expect(manager.hasHandlers('nonexistent'), isFalse);

      manager.addHandler(handler1, channel: 'test');
      expect(manager.hasHandlers('test'), isTrue);
    });

    test('should log to channel handlers', () {
      manager.addHandler(handler1, channel: 'test');
      manager.addHandler(handler2, channel: 'test');

      manager.logToChannel(
        'test',
        LogLevel.info,
        'Test message',
        context: {'key': 'value'},
        stackTrace: StackTrace.current,
      );

      verify(
        handler1.log(
          LogLevel.info,
          'Test message',
          context: {'key': 'value'},
          stackTrace: anyNamed('stackTrace'),
        ),
      ).called(1);

      verify(
        handler2.log(
          LogLevel.info,
          'Test message',
          context: {'key': 'value'},
          stackTrace: anyNamed('stackTrace'),
        ),
      ).called(1);
    });

    test('should close all handlers', () {
      manager.addHandler(handler1, channel: 'test1');
      manager.addHandler(handler2, channel: 'test2');

      manager.closeAll();

      verify(handler1.close()).called(1);
      verify(handler2.close()).called(1);
      expect(manager.channels, isEmpty);
    });
  });
}
