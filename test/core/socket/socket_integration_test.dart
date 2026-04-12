import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:khadem/container.dart';
import 'package:khadem/contracts.dart'
    show EnvInterface, ExceptionHandlerContract;
import 'package:khadem/exception.dart';
import 'package:khadem/logging.dart';

import 'package:khadem/socket.dart'
    show SocketConfig, SocketManager, SocketServer;
import 'package:test/test.dart';

class DummyLogger implements Logger {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class DummyEnv implements EnvInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => 'development';
}

void main() {
  group('SocketServer Integration', () {
    late SocketServer server;
    late SocketManager manager;

    setUp(() async {
      // Register dummy logger to avoid Service Not Found error
      ContainerProvider.instance.singleton<Logger>((_) => DummyLogger());
      // Register ExceptionHandler
      ContainerProvider.instance.singleton<ExceptionHandlerContract>(
        (_) => ExceptionHandler(),
      );
      // Register Env
      ContainerProvider.instance.singleton<EnvInterface>((_) => DummyEnv());

      manager = SocketManager();
      const config = SocketConfig(port: 0); // Use random port
      server = SocketServer(config, manager: manager);
      await server.start();
    });

    tearDown(() async {
      await server.stop();
      ContainerProvider.instance.flush();
    });

    Future<WebSocket> connect() async {
      return WebSocket.connect('ws://localhost:${server.port}');
    }

    test('should connect and receive ping/pong', () async {
      server.routes((router) {
        router.channel('/').on('ping', (context) {
          context.client.send('pong', {'message': 'pong'});
        });
      });

      final ws = await connect();
      final completer = Completer<Map>();

      ws.listen((data) {
        completer.complete(jsonDecode(data));
      });

      ws.add(jsonEncode({'event': 'ping', 'data': {}}));

      final response = await completer.future.timeout(
        const Duration(seconds: 2),
      );
      expect(response['event'], equals('pong'));
      expect(response['data']['message'], equals('pong'));

      await ws.close();
    });

    test('should handle rooms and broadcasting', () async {
      server.routes((router) {
        router.channel('/').on('join', (context) {
          context.client.joinRoom('test_room');
          // Broadcast to everyone in the room
          manager.broadcastToRoom('test_room', 'new_user', {
            'id': context.client.id,
          });
        });
      });

      final ws1 = await connect();
      final ws2 = await connect();

      final ws1Completer = Completer<Map>();
      ws1.listen((data) {
        final msg = jsonDecode(data);
        if (msg['event'] == 'new_user' && !ws1Completer.isCompleted) {
          ws1Completer.complete(msg);
        }
      });

      // WS1 joins room
      ws1.add(jsonEncode({'event': 'join', 'data': {}}));

      // Wait a bit for WS1 to be in room
      await Future.delayed(const Duration(milliseconds: 50));

      // WS2 joins room - this should trigger broadcast to WS1
      ws2.add(jsonEncode({'event': 'join', 'data': {}}));

      final msg = await ws1Completer.future.timeout(const Duration(seconds: 2));
      expect(msg['event'], equals('new_user'));
      expect(msg['data'], isNotNull);

      await ws1.close();
      await ws2.close();
    });

    test('should enforce maxMessageBytes', () async {
      await server.stop();
      manager = SocketManager();
      const config = SocketConfig(
        port: 0,
        maxMessageBytes: 10,
      ); // Very small limit
      server = SocketServer(config, manager: manager);
      await server.start();

      final ws = await connect();
      final completer = Completer<Map>();

      ws.listen((data) {
        completer.complete(jsonDecode(data));
      });

      // Send a large message
      ws.add(
        jsonEncode({
          'event': 'large',
          'data': 'this is definitely larger than 10 bytes',
        }),
      );

      final response = await completer.future.timeout(
        const Duration(seconds: 2),
      );
      expect(response['event'], equals('error'));
      expect(response['data']['status'], equals(413)); // Payload Too Large

      await ws.close();
    });
  });
}
