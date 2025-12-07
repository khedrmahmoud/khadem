import 'dart:async';
import '../../../contracts/events/dispatcher.dart';
import '../../../contracts/events/event.dart';

/// A fake event dispatcher for testing purposes.
///
/// Use this class to assert that events were dispatched without actually
/// running the listeners.
class EventFake implements Dispatcher {
  final List<Event> _dispatchedEvents = [];
  final Map<Type, List<dynamic>> _listeners = {};

  @override
  Future<void> dispatch(Event event) async {
    _dispatchedEvents.add(event);
  }

  @override
  void listen<T extends Event>(dynamic listener) {
    listenType(T, listener);
  }

  @override
  void listenType(Type eventType, dynamic listener) {
    if (_listeners[eventType] == null) {
      _listeners[eventType] = [];
    }
    _listeners[eventType]!.add(listener);
  }

  @override
  void subscribe(dynamic subscriber) {
    // No-op for fake
  }

  @override
  void forget(Type eventType) {
    _listeners.remove(eventType);
  }

  /// Assert that an event of type [T] was dispatched.
  void assertDispatched<T extends Event>([bool Function(T event)? callback]) {
    final events = _dispatchedEvents.whereType<T>();
    if (events.isEmpty) {
      throw Exception('Event $T was not dispatched.');
    }

    if (callback != null) {
      final match = events.any(callback);
      if (!match) {
        throw Exception('Event $T was dispatched but failed callback check.');
      }
    }
  }

  /// Assert that an event of type [T] was NOT dispatched.
  void assertNotDispatched<T extends Event>() {
    final events = _dispatchedEvents.whereType<T>();
    if (events.isNotEmpty) {
      throw Exception('Event $T was dispatched unexpectedly.');
    }
  }

  /// Get all dispatched events.
  List<Event> get dispatched => List.unmodifiable(_dispatchedEvents);
}
