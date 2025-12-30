import 'dart:async';
import '../validation/input_validator.dart';
import 'socket_client.dart';
import 'socket_packet.dart';

/// Represents the context of a WebSocket event/message.
///
/// This class encapsulates the client, the message, and any shared state
/// for the duration of the event processing. It replaces the HTTP-bound
/// [Request] object for WebSocket interactions.
class SocketContext {
  static final _contextKey = Object();

  /// The client that sent the message.
  final SocketClient client;

  /// The parsed socket packet.
  final SocketPacket packet;

  /// Context-specific attributes (local to this message processing).
  final Map<String, dynamic> _attributes = {};

  SocketContext({
    required this.client,
    required this.packet,
  }) {
    // Initialize attributes with message data for convenience
    _attributes['__event'] = packet.event;
    _attributes['__data'] = packet.data;
    if (packet.id != null) {
      _attributes['__id'] = packet.id;
    }
  }

  /// Get the current socket context from the zone.
  static SocketContext get current {
    final context = Zone.current[_contextKey] as SocketContext?;
    if (context == null) {
      throw StateError('SocketContext is not available in the current zone.');
    }
    return context;
  }

  /// Run code in a zone with this context.
  R run<R>(R Function() body) {
    return runZoned(body, zoneValues: {_contextKey: this});
  }

  /// Get the event name.
  String get event => packet.event;

  /// Get the event namespace (e.g., "chat" from "chat:message").
  String? get namespace => packet.namespace;

  /// Get the message payload data.
  dynamic get data => packet.data;

  /// Get the message ID (if any).
  String? get id => packet.id;

  /// Set a context attribute.
  void set(String key, dynamic value) {
    _attributes[key] = value;
  }

  /// Get a context attribute.
  T? get<T>(String key) {
    return _attributes[key] as T?;
  }

  /// Get the payload as a specific type.
  T payload<T>() {
    return data as T;
  }

  /// Validate the payload against rules.
  /// 
  /// Throws [ValidationException] if validation fails.
  Future<void> validate(Map<String, dynamic> rules, {Map<String, String> messages = const {}}) async {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Payload must be a Map to be validated');
    }
    final validator = InputValidator(data as Map<String, dynamic>, rules, customMessages: messages);
    await validator.validate();
  }

  /// Check if an attribute exists.
  bool has(String key) {
    return _attributes.containsKey(key);
  }

  /// Helper to send a reply to the client.
  void emit(String event, dynamic data) {
    client.send(event, data, namespace: packet.namespace);
  }

  /// Helper to send an error reply.
  void error(String message, {int code=400, dynamic details}) {
    client.sendError(message: message, status: code, details: details);
  }
  
  // ===========================================================================
  // Room Management Helpers
  // ===========================================================================

  /// Join a room.
  void join(String room) {
    client.manager.join(room, client);
  }

  /// Leave a room.
  void leave(String room) {
    client.manager.leave(room, client);
  }

  /// Broadcast to a room (including sender).
  void to(String room, String event, dynamic data) {
    client.manager.broadcastToRoom(room, event, data);
  }

  /// Broadcast to a room (excluding sender).
  void broadcastTo(String room, String event, dynamic data) {
    client.manager.broadcastToRoomExcept(room, event, data, {client.id});
  }

  /// Broadcast to all subscribers of the event.
  void broadcast(String event, dynamic data) {
    client.manager.broadcast(event, data);
  }
}
