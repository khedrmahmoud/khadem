import 'dart:async';
import '../../core/events/event_registration.dart';

/// A function type for event listeners that handle event payloads.
///
/// The listener receives a [payload] of any type and can perform asynchronous operations.
/// Implementations should handle exceptions gracefully to avoid disrupting the event system.
///
/// Example:
/// ```dart
/// EventListener myListener = (payload) async {
///   print('Event received: $payload');
/// };
/// ```
typedef EventListener = FutureOr<void> Function(dynamic payload);

/// Defines levels of event listener priority for execution order.
///
/// Listeners with higher priority (e.g., [critical]) are executed before lower ones.
/// This ensures critical handlers run first, such as logging or security checks.
enum EventPriority { low, normal, high, critical }

/// Core event system contract for managing listeners, emitting events, and groups.
///
/// This interface provides a flexible pub-sub system for decoupling components.
/// Implementations should ensure thread-safety if used in concurrent environments.
///
/// Key features:
/// - Register listeners with priorities and one-time execution.
/// - Group events for batch operations.
/// - Emit events synchronously or asynchronously.
/// - Manage subscriptions per subscriber for easy cleanup.
///
/// Example usage:
/// ```dart
/// class MyEventSystem implements EventSystemInterface {
///   // Implementation here
/// }
///
/// final events = MyEventSystem();
/// events.on('user.created', (user) => print('User: $user'));
/// await events.emit('user.created', {'id': 1, 'name': 'Alice'});
/// ```
abstract class EventSystemInterface {
  /// Internal map of event names to their registered listeners.
  final Map<String, List<EventRegistration>> listeners = {};

  /// Internal map of group names to sets of event names.
  final Map<String, Set<String>> eventGroups = {};

  /// Internal map tracking events registered by each subscriber for cleanup.
  final Map<Object, Set<String>> subscriberEvents = {};

  /// Registers a listener for a specific event.
  ///
  /// - [event]: The name of the event (e.g., 'user.created').
  /// - [listener]: The function to call when the event is emitted.
  /// - [priority]: Execution order; higher priority listeners run first.
  /// - [once]: If true, the listener is removed after one execution.
  /// - [subscriber]: Optional object to associate with the listener for bulk removal.
  ///
  /// Listeners are executed in priority order when the event is emitted.
  /// If [subscriber] is provided, it's tracked for [offSubscriber] cleanup.
  ///
  /// Example:
  /// ```dart
  /// events.on('order.placed', handleOrder, priority: EventPriority.high, subscriber: this);
  /// ```
  void on(
    String event,
    EventListener listener, {
    EventPriority priority = EventPriority.normal,
    bool once = false,
    Object? subscriber,
  });

  /// Registers a one-time listener for a specific event.
  ///
  /// This is a convenience method equivalent to [on] with [once: true].
  /// The listener is automatically removed after the first emission.
  ///
  /// - [event]: The name of the event.
  /// - [listener]: The function to call once.
  /// - [priority]: Execution priority.
  /// - [subscriber]: Optional subscriber association.
  ///
  /// Example:
  /// ```dart
  /// events.once('app.startup', initializeApp);
  /// ```
  void once(
    String event,
    EventListener listener, {
    EventPriority priority = EventPriority.normal,
    Object? subscriber,
  });

  /// Adds an event to a named group for batch operations.
  ///
  /// Groups allow emitting multiple related events at once via [emitGroup].
  /// If the group doesn't exist, it's created automatically.
  ///
  /// - [groupName]: The name of the group (e.g., 'user.events').
  /// - [event]: The event name to add to the group.
  ///
  /// Example:
  /// ```dart
  /// events.addToGroup('auth', 'user.login');
  /// events.addToGroup('auth', 'user.logout');
  /// ```
  void addToGroup(String groupName, String event);

  /// Removes an event from a named group.
  ///
  /// If the event isn't in the group or the group doesn't exist, this is a no-op.
  ///
  /// - [groupName]: The name of the group.
  /// - [event]: The event name to remove.
  ///
  /// Example:
  /// ```dart
  /// events.removeFromGroup('auth', 'user.login');
  /// ```
  void removeFromGroup(String groupName, String event);

  /// Emits an event to all its registered listeners.
  ///
  /// Listeners are executed in priority order. If any listener throws, implementations
  /// should catch and handle exceptions to prevent disrupting other listeners.
  ///
  /// - [event]: The event name to emit.
  /// - [payload]: Optional data passed to listeners.
  /// - [queue]: If true, queue the emission for async processing.
  ///
  /// Returns a [Future] that completes when all listeners have finished.
  ///
  /// Example:
  /// ```dart
  /// await events.emit('user.updated', {'userId': 123, 'changes': {...}});
  /// ```
  Future<void> emit(
    String event, [
    dynamic payload,
    bool queue = false,
  ]);

  /// Emits all events within a named group.
  ///
  /// This calls [emit] for each event in the group with the same parameters.
  /// Useful for triggering related events together.
  ///
  /// - [groupName]: The name of the group to emit.
  /// - [payload]: Optional data for all events.
  /// - [queue]: Queue the emissions.
  ///
  /// Returns a [Future] that completes when all group events are emitted.
  ///
  /// Example:
  /// ```dart
  /// await events.emitGroup('user.lifecycle', userData);
  /// ```
  Future<void> emitGroup(
    String groupName, [
    dynamic payload,
    bool queue = false,
  ]);

  /// Removes a specific listener from an event.
  ///
  /// If the listener isn't registered for the event, this is a no-op.
  /// Note: This requires the exact function reference; anonymous functions can't be removed this way.
  ///
  /// - [event]: The event name.
  /// - [listener]: The listener function to remove.
  ///
  /// Example:
  /// ```dart
  /// events.off('user.created', myHandler);
  /// ```
  void off(String event, EventListener listener);

  /// Removes all listeners for a specific event.
  ///
  /// This clears the entire listener list for the event.
  ///
  /// - [event]: The event name to clear.
  ///
  /// Example:
  /// ```dart
  /// events.offEvent('user.created');
  /// ```
  void offEvent(String event);

  /// Removes all events registered by a specific subscriber.
  ///
  /// This is useful for cleanup when a component is destroyed.
  /// All listeners associated with the [subscriber] are removed.
  ///
  /// - [subscriber]: The object whose events to remove.
  ///
  /// Example:
  /// ```dart
  /// events.offSubscriber(this);
  /// ```
  void offSubscriber(Object subscriber);

  /// Checks if any listeners are registered for the event.
  ///
  /// - [event]: The event name to check.
  /// - Returns: True if at least one listener is registered.
  ///
  /// Example:
  /// ```dart
  /// if (events.hasListeners('user.created')) {
  ///   // Handle case with listeners
  /// }
  /// ```
  bool hasListeners(String event);

  /// Returns the number of listeners registered for the event.
  ///
  /// - [event]: The event name.
  /// - Returns: The count of listeners (0 if none).
  ///
  /// Example:
  /// ```dart
  /// print('Listeners for user.created: ${events.listenerCount('user.created')}');
  /// ```
  int listenerCount(String event);

  /// Clears all listeners, event groups, and subscriber tracking.
  ///
  /// This resets the event system to its initial state.
  /// Use with caution, as it removes everything.
  ///
  /// Example:
  /// ```dart
  /// events.clear(); // Reset for testing or shutdown
  /// ```
  void clear();
}
