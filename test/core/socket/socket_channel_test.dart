import 'package:khadem/src/core/socket/channel/socket_channel.dart';
import 'package:khadem/src/core/socket/socket_context.dart';
import 'package:test/test.dart';

void main() {
  group('SocketChannel', () {
    late SocketChannel channel;

    setUp(() {
      channel = SocketChannel('test');
    });

    test('should register and retrieve event handler', () {
      void handler(SocketContext context) {}
      channel.on('event', handler);

      final entry = channel.getEntry('event');
      expect(entry, isNotNull);
      expect(entry!.handler, equals(handler));
    });
  });
}
