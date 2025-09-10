import 'dart:convert';
import 'dart:io';
import 'socket_manager.dart';

class SocketClient {
  final String id;
  final WebSocket socket;
  final SocketManager manager;
  final Set<String> rooms = {};
  final HttpHeaders? headers;

  final Map<String, dynamic> _context  ;

  SocketClient({
    required this.id,
    required this.socket,
    required this.manager,
    this.headers,
    Map<String, dynamic>? context,
  }) : _context = context ?? const {};

  void set(String key, dynamic value) {
    _context[key] = value;
  }

  dynamic get(String key) {
    return _context[key];
  }

  void send(String event, dynamic data) {
    final payload = jsonEncode({'event': event, 'data': data});
    socket.add(payload);
  }

  void close([int code = 1000, String reason = '']) {
    socket.close(code, reason);
    manager.removeClient(this);
  }

  void joinRoom(String room) {
    rooms.add(room);
    manager.join(room, this);
  }
  

  void leaveRoom(String room) {
    rooms.remove(room);
    manager.leave(room, this);
  }

  bool isInRoom(String room) => rooms.contains(room);

  /// Check if client is authorized
  bool get isAuthorized => get('authorized') == true;

  /// Check if client is authenticated (has user info)
  bool get isAuthenticated => get('user') != null;

  /// Get user information from context
  Map<String, dynamic>? get user => get('user');

  /// Get authorization token from headers
  String? get authToken {
    if (headers == null) return null;
    return headers!['authorization']?.first ??
           headers!['Authorization']?.first;
  }

  /// Get user agent from headers
  String? get userAgent {
    if (headers == null) return null;
    return headers!['user-agent']?.first ??
           headers!['User-Agent']?.first;
  }

  /// Get any header value
  String? getHeader(String name) {
    if (headers == null) return null;
    return headers![name]?.first;
  }

  /// Get all values for a header
  List<String>? getHeaderValues(String name) {
    if (headers == null) return null;
    return headers![name];
  }
}
