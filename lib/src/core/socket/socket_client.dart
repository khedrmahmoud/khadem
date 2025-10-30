import 'dart:convert';
import 'dart:io';
import 'package:khadem/khadem.dart';

class SocketClient {
  final String id;
  final WebSocket socket;
  final SocketManager manager;
  final Set<String> rooms = {};
  final HttpHeaders? headers;

  final Request _request;
  Request get request => _request;

  SocketClient({
    required this.id,
    required this.socket,
    required this.manager,
    required Request request,
    this.headers,
  }) : _request = request;

  void set(String key, dynamic value) {
    _request.setAttribute(key, value);
  }

  dynamic get(String key) {
    return _request.attribute(key);
  }

  void send(String event, dynamic data) {
    RequestContext.run(_request, () {
      final payload = jsonEncode({'event': event, 'data': data});
      socket.add(payload);
    });
  }

  void close([int code = 1000, String reason = '']) {
    RequestContext.run(_request, () {
      socket.close(code, reason);
      manager.removeClient(this);
    });
  }

  void joinRoom(String room) {
    RequestContext.run(_request, () {
      rooms.add(room);
      manager.join(room, this);
    });
  }

  void leaveRoom(String room) {
    RequestContext.run(_request, () {
      rooms.remove(room);
      manager.leave(room, this);
    });
  }

  bool isInRoom(String room) => rooms.contains(room);

  /// Check if client is authorized
  bool get isAuthorized => get('authorized') == true;

  /// Check if client is authenticated (has user info)
  bool get isAuthenticated => _request.isAuthenticated;

  Authenticatable? get authenticatedUser => _request.authenticatable;

  /// Get user information from context
  Map<String, dynamic>? get user => _request.user;

  /// Get authorization token from headers
  String? get authToken {
    if (headers == null) return null;
    return headers!['authorization']?.first ?? headers!['Authorization']?.first;
  }

  /// Get user agent from headers
  String? get userAgent {
    if (headers == null) return null;
    return headers!['user-agent']?.first ?? headers!['User-Agent']?.first;
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
