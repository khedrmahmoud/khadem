import '../../contracts/events/event_system_interface.dart';

/// Event registration information with priority and one-time execution flag.
///
/// Used internally by [EventSystem] to store event listeners.
class EventRegistration {
  /// The event listener.
  final EventListener listener;

  /// The priority of the event listener.
  final EventPriority priority;

  /// Whether the event listener should only be called once.
  final bool once;

  /// Whether the listener has been removed.
  ///
  /// Used by [EventSystem] to track whether the listener has been removed.
  bool removed = false;

  /// Creates a new event registration.
  EventRegistration(this.listener, this.priority, this.once);

  /// Compares the priority of this registration with another.
  ///
  /// Used by [EventSystem] to sort event listeners by priority.
  int compareTo(EventRegistration other) {
    return other.priority.index.compareTo(priority.index);
  }
}
