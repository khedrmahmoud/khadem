import 'dart:async';
import '../../contracts/socket/socket_middleware.dart';
import 'socket_client.dart';

class SocketMiddlewarePipeline {
  final List<SocketMiddleware> _middlewares = [];

  void add(SocketMiddleware middleware) {
    _middlewares.add(middleware);
    _middlewares.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  void addAll(List<SocketMiddleware> middlewares) {
    _middlewares.addAll(middlewares);
    _middlewares.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  Future<void> execute(
    SocketClient client,
    dynamic message,
    FutureOr<void> Function() handler,
  ) async {
    var index = 0;

    Future<void> next() async {
      if (index < _middlewares.length) {
        final middleware = _middlewares[index++];
        await middleware.handler(client, message, next);
      } else {
        await handler();
      }
    }

    await next();
  }

  List<SocketMiddleware> getMiddlewares() => _middlewares;

  void clear() => _middlewares.clear();
}
