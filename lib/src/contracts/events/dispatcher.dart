import 'dart:async';
import 'event.dart';

abstract class Dispatcher {
  /// Dispatch an event and call the listeners.
  Future<void> dispatch(Event event);

  /// Register an event listener with the dispatcher.
  void listen<T extends Event>(dynamic listener);

  /// Register an event listener with the dispatcher by type.
  void listenType(Type eventType, dynamic listener);

  /// Register an event subscriber with the dispatcher.
  void subscribe(dynamic subscriber);

  /// Remove a set of listeners from the dispatcher.
  void forget(Type eventType);
}
