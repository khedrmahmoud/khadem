import 'dart:io';
import 'package:khadem/auth.dart' show RequestAuth, Authenticatable;
import 'package:khadem/http.dart';
import 'package:khadem/khadem.dart';
 
import 'socket_manager.dart';
import 'socket_packet.dart';

class SocketClient {
  final String id;
  final WebSocket socket;
  final SocketManager manager;
  final Set<String> rooms = {};
  RequestHeaders get headers => handshakeRequest.headers;

  /// The initial HTTP request that established the WebSocket connection.
  /// This contains the handshake headers, query parameters, and initial attributes.
  final Request handshakeRequest;

  SocketClient({
    required this.id,
    required this.socket,
    required this.manager,
    required Request request,
  }) : handshakeRequest = request;

  /// Sets an attribute on the handshake request context.
  /// These attributes are persistent for the duration of the connection
  /// and are copied to every message request context.
  void set(String key, dynamic value) {
    handshakeRequest.setAttribute(key, value);
  }

  /// Gets an attribute from the handshake request context.
  dynamic get(String key) {
    return handshakeRequest.attribute(key);
  }

  bool _canWrite() {
    // WebSocket.readyState is an int (0..3). We only write when OPEN.
    // 1 == WebSocket.open
    try {
      return socket.readyState == WebSocket.open;
    } catch (_) {
      return false;
    }
  }

  void _runInContext(void Function() body) {
    if (RequestContext.hasRequest) {
      body();
      return;
    }
    RequestContext.run(handshakeRequest, body);
  }

  void sendPacket(SocketPacket packet) {
    if (!_canWrite()) return;

    _runInContext(() {
      try {
        socket.add(packet.toJson());
      } catch (e) {
        // Log serialization errors
        Khadem.logger.error('Failed to serialize socket packet: $e');
      }
    });
  }

  void send(String event, dynamic data, {String? namespace}) {
    sendPacket(SocketPacket(event: event, data: data, namespace: namespace));
  }

  /// Alias for [send].
  void emit(String event, dynamic data, {String? namespace}) =>
      send(event, data, namespace: namespace);

  /// Broadcast to a room (including this client).
  void to(String room, String event, dynamic data) {
    manager.broadcastToRoom(room, event, data);
  }

  /// Broadcast to a room (excluding this client).
  void broadcastTo(String room, String event, dynamic data) {
    manager.broadcastToRoomExcept(room, event, data, {id});
  }

  /// Broadcast to all clients.
  void broadcast(String event, dynamic data) {
    manager.broadcast(event, data);
  }

  /// Acknowledge a received event with optional data.
  void ack(
    String id, {
    required String event,
    int status = 200,
    dynamic data,
  }) {
    sendPacket(
      SocketPacket(
        event: 'ack',
        data: {
          'id': id,
          'event': event,
          'status': status,
          if (data != null) 'data': data,
        },
      ),
    );
  }

  void sendError({
    required String message,
    String? id,
    String? event,
    int status = 400,
    Map<String, dynamic>? details,
  }) {
    sendPacket(
      SocketPacket(
        event: 'error',
        data: {
          'status': status,
          if (id != null) 'id': id,
          if (event != null) 'event': event,
          'message': message,
          if (details != null) 'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  void close([int code = 1000, String reason = '']) {
    _runInContext(() {
      try {
        socket.close(code, reason);
      } catch (_) {
        // Ignore close errors.
      } finally {
        manager.removeClient(this);
      }
    });
  }

  void joinRoom(String room) {
    _runInContext(() {
      rooms.add(room);
      manager.join(room, this);
    });
  }

  void leaveRoom(String room) {
    _runInContext(() {
      rooms.remove(room);
      manager.leave(room, this);
    });
  }

  bool isInRoom(String room) => rooms.contains(room);

  /// Check if client is authenticated (has user info)
  bool get isAuthenticated => handshakeRequest.isAuthenticated;

  Authenticatable? get authenticatedUser => handshakeRequest.authenticatable;

  /// Get user information from context
  Map<String, dynamic>? get user => handshakeRequest.user;

  /// Get authorization token from headers
  String? get authToken {
    return headers.get('authorization') ?? headers.get('Authorization');
  }

  /// Get user agent from headers
  String? get userAgent {
    return headers.get('user-agent') ?? headers.get('User-Agent');
  }

  /// Get any header value
  String? getHeader(String name) {
    return headers.get(name);
  }

  /// Get all values for a header
  List<String>? getHeaderValues(String name) {
    return headers.getAll(name);
  }
}
