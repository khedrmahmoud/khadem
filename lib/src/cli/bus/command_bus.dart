import 'dart:async';

import 'command.dart';

/// Command bus that manages command registration and execution.
class CommandBus {
  final Map<String, CommandHandler> _handlers = {};

  /// Registers a command handler for a specific command type.
  void register<T extends KhademCommand>(CommandHandler<T> handler) {
    final command = _createCommand<T>();
    _handlers[command.name] = handler;
  }

  /// Executes a command using its registered handler.
  Future<void> execute(KhademCommand command) async {
    final handler = _handlers[command.name];
    if (handler == null) {
      throw Exception('No handler registered for command ${command.name}');
    }

    await handler.handle(command);
  }

  /// Creates an instance of a command type for registration.
  T _createCommand<T extends KhademCommand>() {
    try {
      return T as T;
    } catch (e) {
      throw Exception('Failed to create command instance of type $T');
    }
  }

  /// Checks if a handler is registered for a command type.
  bool hasHandler(String commandName) {
    return _handlers.containsKey(commandName);
  }

  /// Removes a command handler registration.
  void unregister(String commandName) {
    _handlers.remove(commandName);
  }
}
