import '../../../contracts/socket/socket_event_handler.dart';
import '../channel/socket_channel.dart';

class SocketRouter {
  final Map<String, SocketChannel> _channels = {};
  late final SocketChannel _global;

  SocketRouter() {
    _global = channel('/');
  }

  SocketChannel get global => _global;

  /// Get or create a channel by name.
  SocketChannel channel(String name) {
    return _channels.putIfAbsent(name, () => SocketChannel(name));
  }

  /// Register an event handler on the global channel.
  void on(String event, SocketEventHandler handler) {
    _global.on(event, handler);
  }

  /// Match a channel by name.
  SocketChannel? match(String? name) {
    if (name == null || name.isEmpty) return _global;
    return _channels[name];
  }
}
