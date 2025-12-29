import 'package:khadem/src/contracts/socket/socket_adapter.dart';

import '../socket_client.dart';

/// Default in-memory implementation of [SocketAdapter].
class InMemorySocketAdapter implements SocketAdapter {
  final Map<String, SocketClient> _clients = {};
  final Map<dynamic, String> _userClientMap = {};
  final Map<String, Set<SocketClient>> _rooms = {};
  final Map<String, Set<SocketClient>> _eventSubscribers = {};

  @override
  void addClient(SocketClient client) {
    _clients[client.id] = client;
    final user = client.authenticatedUser;
    if (user != null && user.getAuthIdentifier() != null) {
      _userClientMap[user.getAuthIdentifier()] = client.id;
    }
  }

  @override
  void removeClient(SocketClient client) {
    _clients.remove(client.id);

    final user = client.authenticatedUser;
    if (user != null && user.getAuthIdentifier() != null) {
      _userClientMap.remove(user.getAuthIdentifierName());
    }

    // Remove from all rooms
    for (final room in client.rooms) {
      _rooms[room]?.remove(client);
      if (_rooms[room]?.isEmpty ?? false) {
        _rooms.remove(room);
      }
    }

    // Remove from all event subscriptions
    for (final subscribers in _eventSubscribers.values) {
      subscribers.remove(client);
    }
    _eventSubscribers.removeWhere((_, subscribers) => subscribers.isEmpty);
  }

  @override
  void join(String room, SocketClient client) {
    _rooms.putIfAbsent(room, () => {}).add(client);
  }

  @override
  void leave(String room, SocketClient client) {
    _rooms[room]?.remove(client);
    if (_rooms[room]?.isEmpty ?? false) {
      _rooms.remove(room);
    }
  }

  @override
  void broadcastToRoom(String room, String event, dynamic data,
      {String? namespace,}) {
    if (!hasRoom(room)) return;
    for (final client in _rooms[room]!) {
      client.send(event, data, namespace: namespace);
    }
  }

  @override
  void broadcastToRoomExcept(
      String room, String event, dynamic data, Set<String> excludedClientIds,
      {String? namespace,}) {
    if (!hasRoom(room)) return;
    for (final client in _rooms[room]!) {
      if (!excludedClientIds.contains(client.id)) {
        client.send(event, data, namespace: namespace);
      }
    }
  }

  @override
  void broadcast(String event, dynamic data, {String? namespace}) {
    final subscribers = _eventSubscribers[event];
    if (subscribers != null && subscribers.isNotEmpty) {
      for (final client in subscribers) {
        client.send(event, data, namespace: namespace);
      }
    }
  }

  @override
  void subscribe(String event, SocketClient client) {
    _eventSubscribers.putIfAbsent(event, () => {}).add(client);
  }

  @override
  void unsubscribe(String event, SocketClient client) {
    _eventSubscribers[event]?.remove(client);
    if (_eventSubscribers[event]?.isEmpty ?? false) {
      _eventSubscribers.remove(event);
    }
  }

  @override
  int subscriberCount(String event) {
    return _eventSubscribers[event]?.length ?? 0;
  }

  @override
  bool hasRoom(String room) {
    return _rooms.containsKey(room) && _rooms[room]!.isNotEmpty;
  }

  @override
  SocketClient? getClient(String id) => _clients[id];

  @override
  bool isSubscribed(String event, SocketClient client) {
    return _eventSubscribers[event]?.contains(client) ?? false;
  }

  @override
  Set<String> subscriptions(SocketClient client) {
    final subscriptions = <String>{};
    for (final entry in _eventSubscribers.entries) {
      if (entry.value.contains(client)) {
        subscriptions.add(entry.key);
      }
    }
    return subscriptions;
  }

  @override
  bool hasSubscribers(String event) {
    return _eventSubscribers.containsKey(event) &&
        (_eventSubscribers[event]?.isNotEmpty ?? false);
  }

  @override
  void sendToUser(dynamic userId, String event, dynamic data) {
    final clientId = _userClientMap[userId];
    if (clientId != null) {
      _clients[clientId]?.send(event, data);
    }
  }

  @override
  void sendToUsers(List<dynamic> userIds, String event, dynamic data) {
    if (userIds.isEmpty) return;

    // Deduplicate userIds and collect valid clients
    final uniqueUserIds = userIds.toSet();
    final clientsToSend = <SocketClient>[];

    for (final userId in uniqueUserIds) {
      final clientId = _userClientMap[userId];
      if (clientId != null) {
        final client = _clients[clientId];
        if (client != null) {
          clientsToSend.add(client);
        }
      }
    }

    // Send to all collected clients
    for (final client in clientsToSend) {
      client.send(event, data);
    }
  }
}
