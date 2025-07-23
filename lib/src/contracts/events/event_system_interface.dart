import 'dart:async';
import '../../core/events/event_registration.dart';

typedef EventListener = FutureOr<void> Function(dynamic payload);

/// Defines levels of event listener priority.
enum EventPriority { low, normal, high, critical }

/// Core event system contract for managing listeners, emitting events, and groups.
abstract class EventSystemInterface {
  final Map<String, List<EventRegistration>> listeners = {};
  final Map<String, Set<String>> eventGroups = {};
  final Map<Object, Set<String>> subscriberEvents = {};

  /// Registers a listener for a specific event.
  void on(
    String event,
    EventListener listener, {
    EventPriority priority = EventPriority.normal,
    bool once = false,
    Object? subscriber,
  });

  /// Registers a one-time listener.
  void once(
    String event,
    EventListener listener, {
    EventPriority priority = EventPriority.normal,
    Object? subscriber,
  });

  /// Adds an event to a named group.
  void addToGroup(String groupName, String event);

  /// Removes an event from a group.
  void removeFromGroup(String groupName, String event);

  /// Emits an event to all its listeners.
  Future<void> emit(String event,
      [dynamic payload, bool queue = false, bool broadcast = false]);

  /// Emits all events within a group.
  Future<void> emitGroup(String groupName,
      [dynamic payload, bool queue = false, bool broadcast = false]);

  /// Removes a specific listener from an event.
  void off(String event, EventListener listener);

  /// Removes all listeners for an event.
  void offEvent(String event);

  /// Removes all events registered by a subscriber.
  void offSubscriber(Object subscriber);

  /// Checks if any listener is registered to the event.
  bool hasListeners(String event);

  /// Returns number of listeners for an event.
  int listenerCount(String event);

  /// Clears all listeners and event groups.
  void clear();
}
