import 'dart:async';
import 'dart:io';
import '../../application/khadem.dart';
import '../../contracts/socket/socket_event_handler.dart';
import '../../contracts/socket/socket_middleware.dart';
import 'socket_client.dart';
import 'socket_handler.dart';
import 'socket_manager.dart';
import 'socket_middleware_pipeline.dart';

/// WebSocket Server entry point for Khadem framework.
class SocketServer {
  final int _port;
  HttpServer? _server;

  late SocketManager _manager;
  final SocketMiddlewarePipeline _globalMiddleware = SocketMiddlewarePipeline();

  SocketServer(this._port, {SocketManager? manager}) {
    _manager = manager ?? Khadem.socket;
  }

  void useMiddleware(SocketMiddleware middleware) {
    _globalMiddleware.add(middleware);
  }

  void on(
    String event,
    SocketEventHandler handler, {
    List<SocketMiddleware> middlewares = const [],
  }) {
    _manager.on(event, handler, middlewares: middlewares);
  }

  void useRoom(String room, List<SocketMiddleware> middlewares) {
    _manager.useRoom(room, middlewares);
  }

  Future<void> start() async {
    _server =
        await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
    Khadem.logger.info('🟢 WebSocket Server started on ws://localhost:$_port');

    _server!.transform(WebSocketTransformer()).listen((ws) {
      final clientId = _generateClientId();
      final client = SocketClient(id: clientId, socket: ws, manager: _manager);
      final handler = SocketHandler(client, _manager, _globalMiddleware);

      _manager.addClient(client);
      handler.init();
    });
  }

  String _generateClientId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  SocketManager get manager => _manager;
}
