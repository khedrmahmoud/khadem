import 'dart:async';

import '../../../contracts/socket/socket_event_handler.dart';
import '../channel/socket_channel.dart';
import '../routing/socket_router.dart';
import '../socket_context.dart';

/// Base class for WebSocket controllers.
///
/// Controllers organize event handlers for a specific domain or namespace.
abstract class SocketController {
  late final SocketChannel _channel;

  /// The namespace for this controller.
  /// Override this to specify a custom namespace (e.g., 'chat').
  /// Defaults to the global namespace ('/').
  String get namespace => '/';

  /// The current socket context.
  ///
  /// This is only available during the execution of an event handler.
  SocketContext get context => SocketContext.current;

  /// Internal method to register the controller with the router.
  void register(SocketRouter router) {
    _channel = router.channel(namespace);

    init();
  }

  /// Initialize event handlers.
  ///
  /// Override this method to register your event listeners using [on] or [onData].
  void init();

  /// Register an event handler.
  void on(String event, SocketEventHandler handler) {
    _channel.on(event, handler);
  }

  /// Register a typed event handler.
  ///
  /// [T] is the expected type of the data payload.
  void onData<T>(String event,
      FutureOr<void> Function(SocketContext context, T data) handler,) {
    _channel.on(event, (context) => handler(context, context.payload<T>()));
  }

  /// Helper to emit an event to the current client.
  void emit(String event, dynamic data) {
    context.emit(event, data);
  }

  /// Helper to broadcast an event to all clients (except sender).
  void broadcast(String event, dynamic data) {
    context.broadcast(event, data);
  }

  /// Helper to broadcast to a specific room.
  void to(String room, String event, dynamic data) {
    context.to(room, event, data);
  }

  /// Helper to join a room.
  void join(String room) {
    context.join(room);
  }

  /// Helper to leave a room.
  void leave(String room) {
    context.leave(room);
  }

  /// Validate the payload against rules.
  void validate(Map<String, String> rules,
      {Map<String, String> messages = const {},}) {
    context.validate(rules, messages: messages);
  }
}
