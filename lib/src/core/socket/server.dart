import 'dart:async';
import 'dart:io';

import 'package:khadem/src/core/index.dart';

import '../../application/khadem.dart';
import '../../contracts/socket/socket_event_handler.dart';
import '../../contracts/socket/socket_middleware.dart';

/// WebSocket Server entry point for Khadem framework.
class SocketServer {
  final int _port;
  final String? host;
  HttpServer? _server;

  late SocketManager _manager;
  final SocketMiddlewarePipeline _globalMiddleware = SocketMiddlewarePipeline();

  // Authorization callbacks
  FutureOr<bool> Function(Request request)? _authCallback;
  FutureOr<void> Function(SocketClient client)? _onConnectCallback;
  FutureOr<void> Function(SocketClient client)? _onDisconnectCallback;

  SocketServer(this._port, {this.host, SocketManager? manager}) {
    _manager = manager ?? Khadem.socket;
    _manager.setGlobalMiddleware(_globalMiddleware);
  }

  void useMiddleware(SocketMiddleware middleware) {
    _globalMiddleware.add(middleware);
  }

  /// Set authorization callback that receives the HTTP request during WebSocket upgrade
  void useAuth(FutureOr<bool> Function(Request request) callback) {
    _authCallback = callback;
  }

  /// Set callback for when a client connects
  void onConnect(FutureOr<void> Function(SocketClient client) callback) {
    _onConnectCallback = callback;
  }

  /// Set callback for when a client disconnects
  void onDisconnect(FutureOr<void> Function(SocketClient client) callback) {
    _onDisconnectCallback = callback;
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
    _server = await HttpServer.bind(
        host != null ? InternetAddress(host!) : InternetAddress.anyIPv4, _port,
        shared: true,);
    Khadem.logger.info(
        '🟢 WebSocket Server started on ws://${host ?? 'localhost'}:$_port',);

    _server!.listen((HttpRequest request) async {
      final req = Request(request);
      RequestContext.run(req, () async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          try {
            // Check authorization if callback is set
            if (_authCallback != null) {
              final isAuthorized = await _authCallback!(req);
              if (!isAuthorized) {
                request.response.statusCode = HttpStatus.unauthorized;
                await request.response.close();
                return;
              }
            }
            // Upgrade to WebSocket
            final ws = await WebSocketTransformer.upgrade(request);
            final clientId = _generateClientId();
            final client = SocketClient(
              id: clientId,
              socket: ws,
              manager: _manager,
              headers: request.headers,
              request: req,
            );
            // Execute connection middleware
            await _globalMiddleware.executeConnection(client, req);

            final handler = SocketHandler(client, _manager, _globalMiddleware);

            _manager.addClient(client);

            // Store authorization headers in client context
            client.set('headers', request.headers);
            client.set('authorized', true);

            // Call onConnect callback
            if (_onConnectCallback != null) {
              try {
                await _onConnectCallback!(client);
              } catch (e, stackTrace) {
                Khadem.logger.error('Error in onConnect callback: $e');
                Khadem.logger.debug('Stack trace: $stackTrace');
              }
            }

            handler.init();

            // Listen for disconnect
            ws.done.then((_) async {
              try {
                // Execute disconnect middleware
                await _globalMiddleware.executeDisconnect(client);

                // Call onDisconnect callback
                if (_onDisconnectCallback != null) {
                  await _onDisconnectCallback!(client);
                }
              } catch (e, stackTrace) {
                Khadem.logger.error('Error in disconnect handling: $e');
                Khadem.logger.debug('Stack trace: $stackTrace');
              }
            });
          } catch (e, stackTrace) {
            Khadem.logger.error('Error during WebSocket upgrade: $e');
            Khadem.logger.debug('Stack trace: $stackTrace');
            try {
              request.response.statusCode = HttpStatus.internalServerError;
              await request.response.close();
            } catch (responseError) {
              // Ignore response errors during error handling
            }
          }
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
        }
      });
    });
  }

  String _generateClientId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  SocketManager get manager => _manager;
}
