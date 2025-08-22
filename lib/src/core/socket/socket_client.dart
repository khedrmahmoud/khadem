import 'dart:convert';
import 'dart:io';
import 'socket_manager.dart';

class SocketClient {
  final String id;
  final WebSocket socket;
  final SocketManager manager;
  final Set<String> rooms = {};

  final Map<String, dynamic> _context = {};

  SocketClient({required this.id, required this.socket, required this.manager});

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
}
