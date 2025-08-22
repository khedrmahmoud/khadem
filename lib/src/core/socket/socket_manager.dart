import '../../contracts/socket/socket_event_handler.dart';
import '../../contracts/socket/socket_middleware.dart';
import 'socket_client.dart';

class _EventEntry {
  final SocketEventHandler handler;
  final List<SocketMiddleware> middlewares;

  _EventEntry(this.handler, this.middlewares);
}

class SocketManager {
  final Map<String, SocketClient> _clients = {};
  final Map<dynamic, String> _userClientMap = {};

  final Map<String, Set<SocketClient>> _rooms = {};
  final Map<String, _EventEntry> _eventHandlers = {};
  final Map<String, List<SocketMiddleware>> _roomMiddlewares = {};

  void addClient(SocketClient client) {
    _clients[client.id] = client;
    final user = client.get('user');
    if (user != null && user['id'] != null) {
      _userClientMap[user['id']] = client.id;
    }
  }

  void removeClient(SocketClient client) {
    _clients.remove(client.id);
    for (final room in client.rooms) {
      _rooms[room]?.remove(client);
      if (_rooms[room]?.isEmpty ?? false) {
        _rooms.remove(room);
      }
    }
    final user = client.get('user');
    if (user != null && user['id'] != null) {
      _userClientMap.remove(user['id']);
    }
  }

  void on(String event, SocketEventHandler handler,
      {List<SocketMiddleware> middlewares = const []}) {
    _eventHandlers[event] = _EventEntry(handler, List.from(middlewares));
  }

  void useRoom(String room, List<SocketMiddleware> middlewares) {
    _roomMiddlewares[room] = List.from(middlewares);
  }

  _EventEntry? getEvent(String event) => _eventHandlers[event];

  List<SocketMiddleware> getRoomMiddlewares(Set<String> rooms) {
    return rooms
        .where((room) => _roomMiddlewares.containsKey(room))
        .expand((room) => _roomMiddlewares[room]!)
        .toList();
  }

  void join(String room, SocketClient client) {
    _rooms.putIfAbsent(room, () => {}).add(client);
    client.rooms.add(room);
  }

  void leave(String room, SocketClient client) {
    _rooms[room]?.remove(client);
    client.rooms.remove(room);
    if (_rooms[room]?.isEmpty ?? false) {
      _rooms.remove(room);
    }
  }

  void broadcast(String room, String event, dynamic data) {
    if (!hasRoom(room)) return;
    _rooms[room]?.forEach((client) => client.send(event, data));
  }

  void sendTo(String id, String event, dynamic data) {
    _clients[id]?.send(event, data);
  }

  void sendToUser(String userId, String event, dynamic data) {
    final clientId = _userClientMap[userId];
    if (clientId != null) {
      _clients[clientId]?.send(event, data);
    }
  }

  SocketClient? getClient(String id) => _clients[id];

  bool hasRoom(String room) => _rooms.containsKey(room);
}
