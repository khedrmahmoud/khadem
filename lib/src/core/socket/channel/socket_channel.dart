import '../../../contracts/socket/socket_event_handler.dart';

/// Represents a specific event registration within a channel.
class SocketEventEntry {
  final SocketEventHandler handler;

  const SocketEventEntry(this.handler);
}

/// Represents a communication channel (namespace) in the socket system.
///
/// Channels allow you to separate concerns by grouping related events.
/// For example, you might have a 'chat' channel and a 'notifications' channel.
class SocketChannel {
  /// The name of the channel (namespace).
  final String name;

  /// Event handlers registered on this channel.
  final Map<String, SocketEventEntry> _handlers = {};

  SocketChannel(this.name);

  /// Register an event handler.
  void on(String event, SocketEventHandler handler) {
    _handlers[event] = SocketEventEntry(handler);
  }

  /// Get the handler entry for a specific event.
  SocketEventEntry? getEntry(String event) {
    return _handlers[event];
  }
}
