import 'dart:async';

import '../../core/socket/socket_client.dart';

typedef SocketNextFunction = FutureOr<void> Function();
typedef SocketMiddlewareHandler = FutureOr<void> Function(
  SocketClient client,
  dynamic message,
  SocketNextFunction next,
);

enum SocketMiddlewarePriority {
  global,
  auth,
  preprocessing,
  business,
  terminating,
}

class SocketMiddleware {
  final SocketMiddlewareHandler _handler;
  final SocketMiddlewarePriority _priority;
  final String _name;

  SocketMiddleware(
    this._handler, {
    SocketMiddlewarePriority priority = SocketMiddlewarePriority.business,
    String? name,
  })  : _priority = priority,
        _name = name ?? 'socket-middleware-\${DateTime.now().millisecondsSinceEpoch}';

  SocketMiddlewareHandler get handler => _handler;
  SocketMiddlewarePriority get priority => _priority;
  String get name => _name;
}
