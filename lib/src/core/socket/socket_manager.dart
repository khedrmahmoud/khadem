import '../../contracts/socket/socket_event_handler.dart';
import '../../contracts/socket/socket_middleware.dart';
import 'socket_client.dart';
import 'socket_middleware_pipeline.dart';

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
  final Map<String, Set<SocketClient>> _eventSubscribers = {};

  // Reference to global middleware pipeline
  SocketMiddlewarePipeline? _globalMiddleware;

  void setGlobalMiddleware(SocketMiddlewarePipeline middleware) {
    _globalMiddleware = middleware;
  }

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
    // Remove client from all event subscriptions
    for (final subscribers in _eventSubscribers.values) {
      subscribers.remove(client);
    }
    // Clean up empty subscriber sets
    _eventSubscribers.removeWhere((event, subscribers) => subscribers.isEmpty);

    final user = client.get('user');
    if (user != null && user['id'] != null) {
      _userClientMap.remove(user['id']);
    }
  }

  void on(
    String event,
    SocketEventHandler handler, {
    List<SocketMiddleware> middlewares = const [],
  }) {
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

  void join(String room, SocketClient client) async {
    // Execute room middleware before joining
    if (_globalMiddleware != null) {
      await _globalMiddleware!.executeRoom(client, room);
    }

    _rooms.putIfAbsent(room, () => {}).add(client);
    client.rooms.add(room);
  }

  void leave(String room, SocketClient client) async {
    // Execute room middleware before leaving
    if (_globalMiddleware != null) {
      await _globalMiddleware!.executeRoom(client, room);
    }

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

  /// Subscribe a client to an event for future broadcasts
  void subscribeToEvent(String event, SocketClient client) {
    _eventSubscribers.putIfAbsent(event, () => {}).add(client);
  }

  /// Unsubscribe a client from an event
  void unsubscribeFromEvent(String event, SocketClient client) {
    _eventSubscribers[event]?.remove(client);
    if (_eventSubscribers[event]?.isEmpty ?? false) {
      _eventSubscribers.remove(event);
    }
  }

  /// Broadcast an event to all clients who have subscribed to it
  void broadcastToEventSubscribers(String event, dynamic data) {
    final subscribers = _eventSubscribers[event];
    if (subscribers != null && subscribers.isNotEmpty) {
      for (final client in subscribers) {
        client.send(event, data);
      }
    }
  }

  /// Broadcast an event to all clients who have registered interest in it
  /// This is an alias for broadcastToEventSubscribers for convenience
  void broadcastEvent(String event, dynamic data) {
    broadcastToEventSubscribers(event, data);
  }

  /// Get the number of subscribers for an event
  int getEventSubscriberCount(String event) {
    return _eventSubscribers[event]?.length ?? 0;
  }

  /// Check if a client is subscribed to an event
  bool isClientSubscribedToEvent(String event, SocketClient client) {
    return _eventSubscribers[event]?.contains(client) ?? false;
  }

  /// Get all events a client is subscribed to
  Set<String> getClientSubscriptions(SocketClient client) {
    final subscriptions = <String>{};
    for (final entry in _eventSubscribers.entries) {
      if (entry.value.contains(client)) {
        subscriptions.add(entry.key);
      }
    }
    return subscriptions;
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

  /// Check if an event has any subscribers
  bool hasEventSubscribers(String event) {
    return _eventSubscribers.containsKey(event) &&
        (_eventSubscribers[event]?.isNotEmpty ?? false);
  }
}
