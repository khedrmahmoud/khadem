import 'package:khadem/src/core/socket/socket_client.dart';

/// Abstract adapter for managing socket state (clients, rooms, broadcasts).
///
/// This allows swapping the in-memory implementation with a distributed one
/// (e.g., Redis) for horizontal scaling.
abstract class SocketAdapter {
  /// Add a client to the adapter.
  void addClient(SocketClient client);

  /// Remove a client from the adapter.
  void removeClient(SocketClient client);

  /// Add a client to a room.
  void join(String room, SocketClient client);

  /// Remove a client from a room.
  void leave(String room, SocketClient client);

  /// Broadcast an event to all clients in a room.
  void broadcastToRoom(String room, String event, dynamic data,
      {String? namespace,});

  /// Broadcast an event to all clients in a room except specific ones.
  void broadcastToRoomExcept(
      String room, String event, dynamic data, Set<String> excludedClientIds,
      {String? namespace,});

  /// Broadcast an event to all clients subscribed to that event.
  void broadcast(String event, dynamic data, {String? namespace});

  /// Subscribe a client to a specific event channel.
  void subscribe(String event, SocketClient client);

  /// Unsubscribe a client from a specific event channel.
  void unsubscribe(String event, SocketClient client);

  /// Get the number of subscribers for an event.
  int subscriberCount(String event);

  /// Check if a room exists (has active clients).
  bool hasRoom(String room);

  /// Get a client by ID.
  SocketClient? getClient(String id);

  /// Check if a client is subscribed to an event.
  bool isSubscribed(String event, SocketClient client);

  /// Get all events a client is subscribed to.
  Set<String> subscriptions(SocketClient client);

  /// Check if an event has any subscribers.
  bool hasSubscribers(String event);

  /// Send a message to a specific user (by user ID).
  /// The adapter is responsible for mapping user ID to client ID(s).
  void sendToUser(dynamic userId, String event, dynamic data);

  /// Send a message to multiple specific users (by user IDs).
  /// The adapter is responsible for mapping user IDs to client ID(s).
  void sendToUsers(List<dynamic> userIds, String event, dynamic data);
}
