/// Interface for events that should be broadcasted to external clients (e.g., via WebSockets).
abstract class ShouldBroadcast {
  /// The channels the event should broadcast on.
  List<String> broadcastOn();

  /// The event's broadcast name.
  String broadcastAs() => runtimeType.toString();

  /// The data to broadcast.
  Map<String, dynamic> broadcastWith() => {};
}
