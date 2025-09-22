import 'dart:async';

import 'package:khadem/src/core/http/request/request.dart';

import '../../core/socket/socket_client.dart';

typedef SocketNextFunction = FutureOr<void> Function();
typedef SocketMiddlewareHandler = FutureOr<void> Function(
  SocketClient client,
  dynamic message,
  SocketNextFunction next,
);

/// Connection middleware handler - runs during WebSocket upgrade
typedef SocketConnectionHandler = FutureOr<void> Function(
  Request request,
  SocketNextFunction next,
);

/// Disconnect middleware handler - runs when client disconnects
typedef SocketDisconnectHandler = FutureOr<void> Function(
  SocketClient client,
  SocketNextFunction next,
);

/// Room middleware handler - runs when joining/leaving rooms
typedef SocketRoomHandler = FutureOr<void> Function(
  SocketClient client,
  String room,
  SocketNextFunction next,
);

enum SocketMiddlewarePriority {
  global,
  connection,
  auth,
  preprocessing,
  business,
  room,
  message,
  terminating,
  disconnect,
}

enum SocketMiddlewareType {
  /// Runs during WebSocket upgrade/connection establishment
  connection,

  /// Runs on every incoming message
  message,

  /// Runs when client joins or leaves rooms
  room,

  /// Runs when client disconnects
  disconnect,

  /// General purpose middleware
  general,
}

class SocketMiddleware {
  final SocketMiddlewareHandler? _handler;
  final SocketConnectionHandler? _connectionHandler;
  final SocketDisconnectHandler? _disconnectHandler;
  final SocketRoomHandler? _roomHandler;
  final SocketMiddlewarePriority _priority;
  final SocketMiddlewareType _type;
  final String _name;

  SocketMiddleware(
    dynamic handler, {
    SocketMiddlewarePriority priority = SocketMiddlewarePriority.business,
    SocketMiddlewareType type = SocketMiddlewareType.general,
    String? name,
  })  : _handler = handler is SocketMiddlewareHandler ? handler : null,
        _connectionHandler =
            handler is SocketConnectionHandler ? handler : null,
        _disconnectHandler =
            handler is SocketDisconnectHandler ? handler : null,
        _roomHandler = handler is SocketRoomHandler ? handler : null,
        _priority = priority,
        _type = type,
        _name = name ??
            'socket-middleware-${DateTime.now().millisecondsSinceEpoch}';

  /// Create a connection middleware
  SocketMiddleware.connection(
    SocketConnectionHandler handler, {
    SocketMiddlewarePriority priority = SocketMiddlewarePriority.connection,
    String? name,
  }) : this(
          handler,
          priority: priority,
          type: SocketMiddlewareType.connection,
          name: name,
        );

  /// Create a message middleware
  SocketMiddleware.message(
    SocketMiddlewareHandler handler, {
    SocketMiddlewarePriority priority = SocketMiddlewarePriority.message,
    String? name,
  }) : this(
          handler,
          priority: priority,
          type: SocketMiddlewareType.message,
          name: name,
        );

  /// Create a room middleware
  SocketMiddleware.room(
    SocketRoomHandler handler, {
    SocketMiddlewarePriority priority = SocketMiddlewarePriority.room,
    String? name,
  }) : this(
          handler,
          priority: priority,
          type: SocketMiddlewareType.room,
          name: name,
        );

  /// Create a disconnect middleware
  SocketMiddleware.disconnect(
    SocketDisconnectHandler handler, {
    SocketMiddlewarePriority priority = SocketMiddlewarePriority.disconnect,
    String? name,
  }) : this(
          handler,
          priority: priority,
          type: SocketMiddlewareType.disconnect,
          name: name,
        );

  SocketMiddlewareHandler? get handler => _handler;
  SocketConnectionHandler? get connectionHandler => _connectionHandler;
  SocketDisconnectHandler? get disconnectHandler => _disconnectHandler;
  SocketRoomHandler? get roomHandler => _roomHandler;
  SocketMiddlewarePriority get priority => _priority;
  SocketMiddlewareType get type => _type;
  String get name => _name;

  /// Check if this middleware handles the given type
  bool canHandle(SocketMiddlewareType type) =>
      _type == type || _type == SocketMiddlewareType.general;
}
