import '../../contracts/logging/log_handler.dart';
import '../../contracts/logging/log_level.dart';

/// Manages log channels and their associated handlers.
/// Provides methods to add, remove, and manage log handlers for different channels.
class LogChannelManager {
  final Map<String, List<LogHandler>> _channels = {};

  /// Gets all registered channels.
  Set<String> get channels => _channels.keys.toSet();

  /// Gets the handlers for a specific channel.
  List<LogHandler> getHandlers(String channel) {
    return List.unmodifiable(_channels[channel] ?? []);
  }

  /// Adds a log handler to a specific channel.
  void addHandler(LogHandler handler, {String channel = 'app'}) {
    _channels[channel] ??= [];
    _channels[channel]!.add(handler);
  }

  /// Removes a log handler from a specific channel.
  void removeHandler(LogHandler handler, {String channel = 'app'}) {
    final handlers = _channels[channel];
    if (handlers != null) {
      handlers.remove(handler);
      if (handlers.isEmpty) {
        _channels.remove(channel);
      }
    }
  }

  /// Removes all handlers from a specific channel.
  void clearChannel(String channel) {
    _channels.remove(channel);
  }

  /// Removes all handlers from all channels.
  void clearAll() {
    _channels.clear();
  }

  /// Checks if a channel has any handlers.
  bool hasHandlers(String channel) {
    return _channels[channel]?.isNotEmpty ?? false;
  }

  /// Logs a message to all handlers in the specified channel.
  void logToChannel(
    String channel,
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final handlers = _channels[channel];
    if (handlers != null) {
      for (final handler in handlers) {
        try {
          handler.log(level, message, context: context, stackTrace: stackTrace);
        } catch (e, stack) {
          // Log handler errors to stderr to avoid infinite loops
          // In a production system, you might want to use a separate error logger
          print('Error in log handler: $e\n$stack');
        }
      }
    }
  }

  /// Closes all handlers in all channels.
  void closeAll() {
    for (final handlers in _channels.values) {
      for (final handler in handlers) {
        try {
          handler.close();
        } catch (e) {
          print('Error closing log handler: $e');
        }
      }
    }
    _channels.clear();
  }
}
