import 'dart:async';
import '../../contracts/socket/socket_middleware.dart';
import '../http/request/request.dart';
import 'socket_client.dart';
import 'socket_exception_handler.dart';

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

  /// Execute connection middleware during WebSocket upgrade
  Future<void> executeConnection(SocketClient client, Request request) async {
    final connectionMiddlewares = _middlewares
        .where((m) => m.canHandle(SocketMiddlewareType.connection))
        .toList();

    var index = 0;

    Future<void> next() async {
      if (index < connectionMiddlewares.length) {
        final middleware = connectionMiddlewares[index++];
        try {
          if (middleware.connectionHandler != null) {
            await middleware.connectionHandler!(client, request, next);
          } else {
            await next();
          }
        } catch (e, stackTrace) {
          SocketExceptionHandler.handleConnectionError(
            client,
            e,
            stackTrace,
            middleware.name,
          );
          // Re-throw the exception to prevent connection establishment
          rethrow;
        }
      }
    }

    await next();
  }

  /// Execute message middleware for incoming messages
  Future<void> executeMessage(SocketClient client, dynamic message) async {
    final messageMiddlewares = _middlewares
        .where((m) => m.canHandle(SocketMiddlewareType.message))
        .toList();

    var index = 0;

    Future<void> next() async {
      if (index < messageMiddlewares.length) {
        final middleware = messageMiddlewares[index++];
        try {
          if (middleware.handler != null) {
            await middleware.handler!(client, message, next);
          } else {
            await next();
          }
        } catch (e, stackTrace) {
          SocketExceptionHandler.handleMiddlewareError(
            client,
            e,
            stackTrace,
            middleware.name,
          );
          // Re-throw the exception to prevent message processing
          rethrow;
        }
      }
    }

    await next();
  }

  /// Execute room middleware when joining/leaving rooms
  Future<void> executeRoom(SocketClient client, String room) async {
    final roomMiddlewares = _middlewares
        .where((m) => m.canHandle(SocketMiddlewareType.room))
        .toList();

    var index = 0;

    Future<void> next() async {
      if (index < roomMiddlewares.length) {
        final middleware = roomMiddlewares[index++];
        try {
          if (middleware.roomHandler != null) {
            await middleware.roomHandler!(client, room, next);
          } else {
            await next();
          }
        } catch (e, stackTrace) {
          SocketExceptionHandler.handleMiddlewareError(
            client,
            e,
            stackTrace,
            middleware.name,
          );
          // Re-throw the exception to prevent room operation
          rethrow;
        }
      }
    }

    await next();
  }

  /// Execute disconnect middleware when client disconnects
  Future<void> executeDisconnect(SocketClient client) async {
    final disconnectMiddlewares = _middlewares
        .where((m) => m.canHandle(SocketMiddlewareType.disconnect))
        .toList();

    var index = 0;

    Future<void> next() async {
      if (index < disconnectMiddlewares.length) {
        final middleware = disconnectMiddlewares[index++];
        try {
          if (middleware.disconnectHandler != null) {
            await middleware.disconnectHandler!(client, next);
          } else {
            await next();
          }
        } catch (e, stackTrace) {
          SocketExceptionHandler.handleMiddlewareError(
            client,
            e,
            stackTrace,
            middleware.name,
          );
          // Don't continue with next middleware if one fails
          return;
        }
      }
    }

    await next();
  }

  /// Execute general middleware (legacy support)
  Future<void> execute(
    SocketClient client,
    dynamic message,
    FutureOr<void> Function() handler,
  ) async {
    final generalMiddlewares = _middlewares
        .where((m) => m.canHandle(SocketMiddlewareType.general))
        .toList();

    var index = 0;

    Future<void> next() async {
      if (index < generalMiddlewares.length) {
        final middleware = generalMiddlewares[index++];
        try {
          if (middleware.handler != null) {
            await middleware.handler!(client, message, next);
          } else {
            await next();
          }
        } catch (e, stackTrace) {
          SocketExceptionHandler.handleMiddlewareError(
            client,
            e,
            stackTrace,
            middleware.name,
          );
          // Don't continue with next middleware if one fails
          return;
        }
      } else {
        try {
          await handler();
        } catch (e, stackTrace) {
          SocketExceptionHandler.handle(client, e, stackTrace);
        }
      }
    }

    await next();
  }

  List<SocketMiddleware> getMiddlewares() => _middlewares;

  void clear() => _middlewares.clear();

  /// Get middleware by type
  List<SocketMiddleware> getMiddlewareByType(SocketMiddlewareType type) {
    return _middlewares.where((m) => m.canHandle(type)).toList();
  }

  /// Check if pipeline has middleware of specific type
  bool hasMiddlewareType(SocketMiddlewareType type) {
    return _middlewares.any((m) => m.canHandle(type));
  }
}
