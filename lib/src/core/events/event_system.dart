import 'dart:async';
import '../../contracts/events/event_system_interface.dart';
import 'event_registration.dart';

/// A concrete implementation of [EventSystemInterface].
///
/// This event system supports:
/// - Priority-based event listeners.
/// - One-time listeners.
/// - Grouped events.
/// - Subscriber-aware management.
/// - Optional queued execution.
/// - Future support for broadcasting events.
class EventSystem implements EventSystemInterface {
  /// Stores event listeners mapped by event name.
  final Map<String, List<EventRegistration>> _listeners = {};

  /// Stores grouped events by group name.
  final Map<String, Set<String>> _eventGroups = {};

  /// Stores all events registered by a subscriber.
  final Map<Object, Set<String>> _subscriberEvents = {};

  EventSystem();

  /// Registers a listener for an [event].
  ///
  /// - [priority] controls execution order.
  /// - [once] marks it for auto-removal after first call.
  /// - [subscriber] binds this listener to a specific object.
  @override
  void on(
    String event,
    EventListener listener, {
    EventPriority priority = EventPriority.normal,
    bool once = false,
    Object? subscriber,
  }) {
    _listeners[event] ??= [];
    _listeners[event]!.add(EventRegistration(listener, priority, once));
    _listeners[event]!.sort((a, b) => a.compareTo(b));

    if (subscriber != null) {
      _subscriberEvents[subscriber] ??= {};
      _subscriberEvents[subscriber]!.add(event);
    }
  }

  /// Registers a one-time listener for [event].
  ///
  /// It will be removed automatically after being fired.
  @override
  void once(
    String event,
    EventListener listener, {
    EventPriority priority = EventPriority.normal,
    Object? subscriber,
  }) {
    on(event, listener, priority: priority, once: true, subscriber: subscriber);
  }

  /// Adds an [event] to a named group [groupName].
  @override
  void addToGroup(String groupName, String event) {
    _eventGroups[groupName] ??= {};
    _eventGroups[groupName]!.add(event);
  }

  /// Removes an [event] from group [groupName].
  @override
  void removeFromGroup(String groupName, String event) {
    _eventGroups[groupName]?.remove(event);
    if (_eventGroups[groupName]?.isEmpty ?? false) {
      _eventGroups.remove(groupName);
    }
  }

  /// Emits a single [event] with optional [payload].
  ///
  /// - If [queue] is true, the listener runs asynchronously.
  /// - If [broadcast] is true, the event will be logged for broadcasting.
  @override
  Future<void> emit(
    String event, [
    dynamic payload,
    bool queue = false,
    bool broadcast = false,
  ]) async {
    final listeners = _listeners[event];

    if (listeners == null || listeners.isEmpty) return;

    final listenersCopy = List<EventRegistration>.from(listeners);
    final toRemove = <EventRegistration>[];

    for (final registration in listenersCopy) {
      if (registration.removed) continue;

      if (queue) {
        Future(() async {
          await registration.listener(payload);
        });
      } else {
        await registration.listener(payload);
      }

      if (registration.once) {
        registration.removed = true;
        toRemove.add(registration);
      }

      if (broadcast) {
        // TODO: Add actual broadcast integration
        print('[Broadcast] $event → $payload');
      }
    }

    if (toRemove.isNotEmpty) {
      listeners.removeWhere((reg) => reg.removed);
    }
  }

  /// Emits all events inside a [groupName] with optional [payload].
  ///
  /// Runs each event using [emit] logic.
  @override
  Future<void> emitGroup(String groupName,
      [dynamic payload, bool queue = false, bool broadcast = false]) async {
    final events = _eventGroups[groupName];
    if (events == null) return;

    for (final event in events) {
      await emit(event, payload, queue, broadcast);
    }
  }

  /// Removes a specific [listener] from an [event].
  @override
  void off(String event, EventListener listener) {
    _listeners[event]?.removeWhere((reg) => reg.listener == listener);
    if (_listeners[event]?.isEmpty ?? false) {
      _listeners.remove(event);
    }
  }

  /// Removes all listeners registered for a specific [event].
  @override
  void offEvent(String event) {
    _listeners.remove(event);
    for (final group in _eventGroups.values) {
      group.remove(event);
    }
    _eventGroups.removeWhere((_, events) => events.isEmpty);

    for (final subscriber in _subscriberEvents.keys) {
      _subscriberEvents[subscriber]?.remove(event);
    }

    _subscriberEvents.removeWhere((_, events) => events.isEmpty);
  }

  /// Removes all events registered by a specific [subscriber].
  @override
  void offSubscriber(Object subscriber) {
    final events = _subscriberEvents[subscriber];
    if (events == null) return;

    for (final event in events) {
      _listeners[event]?.removeWhere(
          (reg) => _subscriberEvents[subscriber]?.contains(event) ?? false);
      if (_listeners[event]?.isEmpty ?? false) {
        _listeners.remove(event);
      }
    }

    _subscriberEvents.remove(subscriber);
  }

  /// Checks if an [event] has active listeners.
  @override
  bool hasListeners(String event) => _listeners[event]?.isNotEmpty ?? false;

  /// Returns the number of listeners attached to [event].
  @override
  int listenerCount(String event) => _listeners[event]?.length ?? 0;

  /// Clears all event listeners, groups, and subscribers.
  @override
  void clear() {
    _listeners.clear();
    _eventGroups.clear();
    _subscriberEvents.clear();
  }

  /// Returns all registered event groups.
  @override
  Map<String, Set<String>> get eventGroups => _eventGroups;

  /// Returns all event listeners.
  @override
  Map<String, List<EventRegistration>> get listeners => _listeners;

  /// Returns all subscriber-specific event mappings.
  @override
  Map<Object, Set<String>> get subscriberEvents => _subscriberEvents;
}
