import 'package:khadem/src/contracts/socket/socket_adapter.dart';

import 'socket_adapters/in_memory_socket_adapter.dart';
import 'socket_client.dart';

/// Manages the state of WebSocket clients, rooms, and event subscriptions.
///
/// This class delegates the actual state management to a [SocketAdapter],
/// allowing for different implementations (e.g., in-memory, Redis).
class SocketManager {
  final SocketAdapter _adapter;

  SocketManager({SocketAdapter? adapter})
      : _adapter = adapter ?? InMemorySocketAdapter();

  /// Add a new client to the manager.
  void addClient(SocketClient client) {
    _adapter.addClient(client);
  }

  /// Remove a client from the manager.
  void removeClient(SocketClient client) {
    _adapter.removeClient(client);
  }

  /// Add a client to a room.
  void join(String room, SocketClient client) {
    _adapter.join(room, client);
    client.rooms.add(room);
  }

  /// Remove a client from a room.
  void leave(String room, SocketClient client) {
    _adapter.leave(room, client);
    client.rooms.remove(room);
  }

  /// Broadcast an event to all clients in a room.
  void broadcastToRoom(String room, String event, dynamic data,
      {String? namespace,}) {
    _adapter.broadcastToRoom(room, event, data, namespace: namespace);
  }

  /// Broadcast an event to all clients in a room except specific ones.
  void broadcastToRoomExcept(
      String room, String event, dynamic data, Set<String> excludedClientIds,
      {String? namespace,}) {
    _adapter.broadcastToRoomExcept(room, event, data, excludedClientIds,
        namespace: namespace,);
  }

  /// Subscribe a client to an event for future broadcasts.
  void subscribe(String event, SocketClient client) {
    _adapter.subscribe(event, client);
  }

  /// Unsubscribe a client from an event.
  void unsubscribe(String event, SocketClient client) {
    _adapter.unsubscribe(event, client);
  }

  /// Broadcast an event to all clients who have subscribed to it.
  void broadcast(String event, dynamic data, {String? namespace}) {
    _adapter.broadcast(event, data, namespace: namespace);
  }

  /// Get the number of subscribers for an event.
  int subscriberCount(String event) {
    return _adapter.subscriberCount(event);
  }

  /// Check if a room exists (has active clients).
  bool hasRoom(String room) {
    return _adapter.hasRoom(room);
  }

  /// Check if a client is subscribed to an event.
  bool isSubscribed(String event, SocketClient client) {
    return _adapter.isSubscribed(event, client);
  }

  /// Get all events a client is subscribed to.
  Set<String> subscriptions(SocketClient client) {
    return _adapter.subscriptions(client);
  }

  /// Send a message to a specific client by ID.
  void sendTo(String id, String event, dynamic data) {
    _adapter.getClient(id)?.send(event, data);
  }

  /// Send a message to a specific user by User ID.
  ///
  /// Requires clients to be authenticated and have a user ID.
  void sendToUser(dynamic userId, String event, dynamic data) {
    _adapter.sendToUser(userId, event, data);
  }

  /// Send a message to multiple specific users by User IDs.
  ///
  /// Requires clients to be authenticated and have user IDs.
  void sendToUsers(List<dynamic> userIds, String event, dynamic data) {
    _adapter.sendToUsers(userIds, event, data);
  }

  /// Get a client instance by ID.
  SocketClient? getClient(String id) => _adapter.getClient(id);

  /// Check if an event has any subscribers.
  bool hasSubscribers(String event) {
    return _adapter.hasSubscribers(event);
  }
}
