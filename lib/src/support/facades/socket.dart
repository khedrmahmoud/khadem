import '../../application/khadem.dart';
import '../../core/socket/socket_client.dart';
import '../../core/socket/socket_manager.dart';

/// Facade for the Socket system.
class Socket {
  /// Gets the socket manager instance.
  static SocketManager get _manager => Khadem.make<SocketManager>();

  /// Send a message to a specific client by ID.
  static void sendTo(String id, String event, dynamic data) {
    _manager.sendTo(id, event, data);
  }

  /// Send a message to a specific user by User ID.
  ///
  /// Requires clients to be authenticated and have a user ID.
  static void sendToUser(dynamic userId, String event, dynamic data) {
    _manager.sendToUser(userId, event, data);
  }

  /// Send a message to multiple specific users by User IDs.
  ///
  /// Requires clients to be authenticated and have user IDs.
  static void sendToUsers(List<dynamic> userIds, String event, dynamic data) {
    _manager.sendToUsers(userIds, event, data);
  }

  /// Broadcast an event to all clients in a room.
  static void broadcastToRoom(String room, String event, dynamic data,
      {String? namespace,}) {
    _manager.broadcastToRoom(room, event, data, namespace: namespace);
  }

  /// Broadcast an event to all clients in a room except specific ones.
  static void broadcastToRoomExcept(
      String room, String event, dynamic data, Set<String> excludedClientIds,
      {String? namespace,}) {
    _manager.broadcastToRoomExcept(room, event, data, excludedClientIds,
        namespace: namespace,);
  }

  /// Broadcast an event to all clients who have subscribed to it.
  static void broadcast(String event, dynamic data, {String? namespace,}) {
    _manager.broadcast(event, data, namespace: namespace);
  }

  /// Check if a room exists (has active clients).
  static bool hasRoom(String room) {
    return _manager.hasRoom(room);
  }

  /// Get the number of subscribers for an event.
  static int subscriberCount(String event) {
    return _manager.subscriberCount(event);
  }

  /// Check if an event has any subscribers.
  static bool hasSubscribers(String event) {
    return _manager.hasSubscribers(event);
  }

  /// Get a client instance by ID.
  static SocketClient? getClient(String id) => _manager.getClient(id);

  /// Add a new client to the manager.
  static void addClient(SocketClient client) {
    _manager.addClient(client);
  }

  /// Remove a client from the manager.
  static void removeClient(SocketClient client) {
    _manager.removeClient(client);
  }

  /// Add a client to a room.
  static void joinRoom(String room, SocketClient client) {
    _manager.join(room, client);
  }

  /// Remove a client from a room.
  static void leaveRoom(String room, SocketClient client) {
    _manager.leave(room, client);
  }

  /// Subscribe a client to an event for future broadcasts.
  static void subscribe(String event, SocketClient client) {
    _manager.subscribe(event, client);
  }

  /// Unsubscribe a client from an event.
  static void unsubscribe(String event, SocketClient client) {
    _manager.unsubscribe(event, client);
  }

  /// Check if a client is subscribed to an event.
  static bool isSubscribed(String event, SocketClient client) {
    return _manager.isSubscribed(event, client);
  }

  /// Get all events a client is subscribed to.
  static Set<String> getSubscriptions(SocketClient client) {
    return _manager.subscriptions(client);
  }
}
