import 'dart:async';
import 'dart:io';

import 'package:khadem/src/core/index.dart';

import '../../application/khadem.dart';
import '../../contracts/http/middleware_contract.dart';
import '../../contracts/socket/socket_event_handler.dart';

/// WebSocket Server entry point for Khadem framework.
///
/// This class manages the WebSocket server lifecycle, including:
/// - Starting and stopping the server
/// - Handling WebSocket upgrades
/// - Managing client connections
/// - Routing events to handlers
/// - Executing middlewares
class SocketServer {
  /// The configuration for the socket server.
  final SocketConfig config;

  HttpServer? _server;

  late SocketManager _manager;
  final SocketRouter _router = SocketRouter();
  final List<Middleware> _handshakeMiddlewares = [];

  FutureOr<void> Function(SocketClient client)? _onConnectCallback;
  FutureOr<void> Function(SocketClient client)? _onDisconnectCallback;

  SocketServer(
    this.config, {
    SocketManager? manager,
  }) {
    _manager = manager ?? Khadem.socket;
  }

  /// Add a middleware to run during the handshake phase (before upgrade).
  /// This is useful for authentication, CORS, etc.
  void useHandshakeMiddleware(
    List<Middleware> middlewares,
  ) {
    _handshakeMiddlewares.addAll(middlewares);
  }

  /// Define socket routes and their events.
  void routes(void Function(SocketRouter router) callback) {
    callback(_router);
  }

  /// Register a socket controller.
  ///
  /// Controllers organize event handlers for a specific domain.
  void registerController(SocketController controller) {
    controller.register(_router);
  }

  /// Set callback for when a client connects.
  void onConnect(FutureOr<void> Function(SocketClient client) callback) {
    _onConnectCallback = callback;
  }

  /// Set callback for when a client disconnects.
  void onDisconnect(FutureOr<void> Function(SocketClient client) callback) {
    _onDisconnectCallback = callback;
  }

  /// Register a global event handler.
  void on(String event, SocketEventHandler handler) {
    _router.on(event, handler);
  }

  /// Start the WebSocket server.
  Future<void> start() async {
    _server = await HttpServer.bind(
      config.host != null
          ? InternetAddress(config.host!)
          : InternetAddress.anyIPv4,
      config.port,
      shared: config.shared,
    );
    Khadem.logger.info(
      '🟢 WebSocket Server started on ws://${config.host ?? 'localhost'}:${config.port}',
    );

    _server!.listen((HttpRequest request) async {
      final req = Request(request);
      RequestContext.run(req, () async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          try {
            final res = Response(request);

            await MiddlewarePipeline.execute(
              _handshakeMiddlewares,
              req,
              res,
              (req, res) async {
                // Handshake passed
              },
            );

            if (res.sent) return;

            final ws = await WebSocketTransformer.upgrade(request);
            if (config.pingInterval != null) {
              ws.pingInterval = config.pingInterval;
            }

            final clientId = _generateClientId();
            final client = SocketClient(
              id: clientId,
              socket: ws,
              manager: _manager,
              request: req,
            );

            final handler = SocketHandler(
              client: client,
              manager: _manager,
              router: _router,
              maxMessageBytes: config.maxMessageBytes,
            );

            _manager.addClient(client);

            if (_onConnectCallback != null) {
              try {
                await _onConnectCallback!(client);
              } catch (e) {
                Khadem.logger.error('Error in onConnect: $e');
              }
            }

            handler.init();

            ws.done.then((_) async {
              _manager.removeClient(client);
              if (_onDisconnectCallback != null) {
                try {
                  await _onDisconnectCallback!(client);
                } catch (e) {
                  Khadem.logger.error('Error in onDisconnect: $e');
                }
              }
            });
          } catch (e) {
            Khadem.logger.error('WebSocket upgrade error: $e');
            try {
              request.response.statusCode = HttpStatus.internalServerError;
              await request.response.close();
            } catch (_) {}
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
  SocketRouter get router => _router;
  int get port => _server?.port ?? config.port;

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}
