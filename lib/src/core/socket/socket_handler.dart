import 'dart:convert';
import '../../application/khadem.dart';
import 'socket_client.dart';
import 'socket_exception_handler.dart';
import 'socket_manager.dart';
import 'socket_middleware_pipeline.dart';

class SocketHandler {
  final SocketClient _client;
  final SocketManager _manager;
  final SocketMiddlewarePipeline _globalMiddleware;

  SocketHandler(this._client, this._manager, this._globalMiddleware);

  void init() {
    _client.socket.listen(
      (raw) async {
        try {
          final Map<String, dynamic> message =
              jsonDecode(raw as String) as Map<String, dynamic>;
          final String event = message['event'] as String;
          final dynamic data = message['data'];

          // Execute message middleware first
          await _globalMiddleware.executeMessage(_client, message);

          final eventEntry = _manager.getEvent(event);

          if (eventEntry == null) {
            _client.send('error', 'Event not registered: $event');
            return;
          }

          final pipeline = SocketMiddlewarePipeline();
          pipeline.addAll(_globalMiddleware.getMiddlewares());
          pipeline.addAll(_manager.getRoomMiddlewares(_client.rooms));
          pipeline.addAll(eventEntry.middlewares);

          await pipeline.execute(_client, data, () async {
            await eventEntry.handler(_client, data);
          });
        } catch (e, stackTrace) {
          SocketExceptionHandler.handle(_client, e, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        SocketExceptionHandler.handle(_client, error, stackTrace);
      },
      onDone: () {
        _manager.removeClient(_client);
        Khadem.logger.info('🔴 Client disconnected: ${_client.id}');
      },
    );
  }
}
