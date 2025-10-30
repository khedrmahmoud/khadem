import 'dart:async';
import '../../application/khadem.dart';
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
  /// Internal storage for event listeners.
  ///
  /// Maps event names to lists of registered listeners, sorted by priority.
  /// Each event can have multiple listeners with different priorities.
  final Map<String, List<EventRegistration>> _listeners = {};

  /// Internal storage for event groups.
  ///
  /// Maps group names to sets of event names, allowing batch operations
  /// on related events.
  final Map<String, Set<String>> _eventGroups = {};

  /// Internal storage for subscriber event tracking.
  ///
  /// Maps subscriber objects to sets of events they're listening to,
  /// enabling easy cleanup when subscribers are destroyed.
  final Map<Object, Set<String>> _subscriberEvents = {};

  /// Creates a new EventSystem instance.
  ///
  /// Initializes empty collections for listeners, groups, and subscriber tracking.
  EventSystem();

  /// Registers a listener for an [event].
  ///
  /// Adds a new event listener with the specified priority and options.
  /// Listeners are automatically sorted by priority (highest first).
  ///
  /// [event] - The name of the event to listen for
  /// [listener] - The function to call when the event is emitted
  /// [priority] - Execution priority (higher priority listeners run first)
  /// [once] - Whether to remove the listener after first execution
  /// [subscriber] - Optional object to associate with this listener for cleanup
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
  /// Creates a listener that will be automatically removed after its first execution.
  /// This is a convenience method that calls [on] with [once: true].
  ///
  /// [event] - The name of the event to listen for
  /// [listener] - The function to call once when the event is emitted
  /// [priority] - Execution priority for the listener
  /// [subscriber] - Optional object to associate with this listener
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
  ///
  /// Groups allow you to organize related events and emit them together
  /// using [emitGroup]. If the group doesn't exist, it will be created.
  ///
  /// [groupName] - The name of the group to add the event to
  /// [event] - The event name to add to the group
  @override
  void addToGroup(String groupName, String event) {
    _eventGroups[groupName] ??= {};
    _eventGroups[groupName]!.add(event);
  }

  /// Removes an [event] from group [groupName].
  ///
  /// Removes the specified event from the group. If the group becomes empty
  /// after removal, the entire group is removed from the system.
  ///
  /// [groupName] - The name of the group to remove the event from
  /// [event] - The event name to remove from the group
  @override
  void removeFromGroup(String groupName, String event) {
    _eventGroups[groupName]?.remove(event);
    if (_eventGroups[groupName]?.isEmpty ?? false) {
      _eventGroups.remove(groupName);
    }
  }

  /// Emits a single [event] with optional [payload].
  ///
  /// Triggers all listeners registered for the event, executing them in priority order.
  /// One-time listeners are automatically removed after execution.
  ///
  /// [event] - The name of the event to emit
  /// [payload] - Optional data to pass to all listeners
  /// [queue] - Whether to execute listeners asynchronously in separate futures
  /// Returns a Future that completes when all listeners have finished executing
  @override
  Future<void> emit(
    String event, [
    dynamic payload,
    bool queue = false,
  ]) async {
    final listeners = _listeners[event];

    if (listeners == null || listeners.isEmpty) return;

    final listenersCopy = List<EventRegistration>.from(listeners);
    final toRemove = <EventRegistration>[];

    if (queue) {
      // Execute listeners asynchronously but wait for all to complete
      final futures = <Future>[];
      for (final registration in listenersCopy) {
        if (registration.removed) continue;

        futures.add(
          Future(() async {
            try {
              await registration.listener(payload);
            } catch (e, stackTrace) {
              Khadem.logger.error(
                'Event listener error for event "$event": $e',
                stackTrace: stackTrace,
              );
            }
          }),
        );

        if (registration.once) {
          registration.removed = true;
          toRemove.add(registration);
        }
      }

      // Wait for all async listeners to complete
      await Future.wait(futures);
    } else {
      // Execute listeners synchronously
      for (final registration in listenersCopy) {
        if (registration.removed) continue;

        try {
          await registration.listener(payload);
        } catch (e) {
          // Log exception but don't rethrow to prevent disrupting other listeners
          // In a real application, you might want to log this
        }

        if (registration.once) {
          registration.removed = true;
          toRemove.add(registration);
        }
      }
    }

    if (toRemove.isNotEmpty) {
      // Rebuild the listeners list without the removed registrations
      final remaining = listeners.where((reg) => !reg.removed).toList();
      listeners.clear();
      listeners.addAll(remaining);
    }
  }

  /// Emits all events inside a [groupName] with optional [payload].
  ///
  /// Triggers all events that belong to the specified group by calling [emit]
  /// for each event in the group with the same parameters.
  ///
  /// [groupName] - The name of the event group to emit
  /// [payload] - Optional data to pass to all event listeners
  /// [queue] - Whether to execute listeners asynchronously
  /// Returns a Future that completes when all group events have been emitted
  @override
  Future<void> emitGroup(
    String groupName, [
    dynamic payload,
    bool queue = false,
  ]) async {
    final events = _eventGroups[groupName];
    if (events == null) return;

    for (final event in events) {
      await emit(event, payload, queue);
    }
  }

  /// Removes a specific [listener] from an [event].
  ///
  /// Removes the exact listener function from the specified event.
  /// Note: This requires the exact function reference to work properly.
  ///
  /// [event] - The event name to remove the listener from
  /// [listener] - The specific listener function to remove
  @override
  void off(String event, EventListener listener) {
    _listeners[event]?.removeWhere((reg) => reg.listener == listener);
    if (_listeners[event]?.isEmpty ?? false) {
      _listeners.remove(event);
    }
  }

  /// Removes all listeners registered for a specific [event].
  ///
  /// Completely clears all listeners for the event and removes the event
  /// from all groups and subscriber tracking.
  ///
  /// [event] - The event name to clear all listeners for
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
  ///
  /// Removes all listeners that were registered with the specified subscriber
  /// object. This is useful for cleanup when a component is destroyed.
  ///
  /// [subscriber] - The subscriber object whose events should be removed
  @override
  void offSubscriber(Object subscriber) {
    final events = _subscriberEvents[subscriber];
    if (events == null) return;

    for (final event in events) {
      _listeners[event]?.removeWhere(
        (reg) => _subscriberEvents[subscriber]?.contains(event) ?? false,
      );
      if (_listeners[event]?.isEmpty ?? false) {
        _listeners.remove(event);
      }
    }

    _subscriberEvents.remove(subscriber);
  }

  /// Checks if an [event] has active listeners.
  ///
  /// Returns true if there are any listeners registered for the event.
  ///
  /// [event] - The event name to check
  /// Returns true if the event has at least one listener
  @override
  bool hasListeners(String event) => _listeners[event]?.isNotEmpty ?? false;

  /// Returns the number of listeners attached to [event].
  ///
  /// Returns the count of active listeners for the specified event.
  ///
  /// [event] - The event name to count listeners for
  /// Returns the number of listeners (0 if none)
  @override
  int listenerCount(String event) => _listeners[event]?.length ?? 0;

  /// Clears all event listeners, groups, and subscribers.
  ///
  /// Resets the event system to its initial state, removing all
  /// listeners, event groups, and subscriber tracking.
  @override
  void clear() {
    _listeners.clear();
    _eventGroups.clear();
    _subscriberEvents.clear();
  }

  /// Returns all registered event groups.
  ///
  /// Provides read-only access to the internal event groups map.
  /// This is useful for debugging and inspection.
  ///
  /// Returns a map of group names to sets of event names
  @override
  Map<String, Set<String>> get eventGroups => _eventGroups;

  /// Returns all event listeners.
  ///
  /// Provides read-only access to the internal listeners map.
  /// This is useful for debugging and inspection.
  ///
  /// Returns a map of event names to lists of event registrations
  @override
  Map<String, List<EventRegistration>> get listeners => _listeners;

  /// Returns all subscriber-specific event mappings.
  ///
  /// Provides read-only access to the internal subscriber tracking map.
  /// This is useful for debugging and inspection.
  ///
  /// Returns a map of subscriber objects to sets of event names
  @override
  Map<Object, Set<String>> get subscriberEvents => _subscriberEvents;
}
