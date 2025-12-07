/// Base class for all application events.
///
/// Events serve as data containers that hold information related to
/// a specific occurrence in the application.
abstract class Event {
  /// The time when the event occurred.
  final DateTime timestamp = DateTime.now();
}

/// Interface for events that can be stopped from propagating.
abstract class StoppableEvent extends Event {
  bool _isPropagationStopped = false;

  /// Checks if the event propagation has been stopped.
  bool get isPropagationStopped => _isPropagationStopped;

  /// Stops the event from being processed by further listeners.
  void stopPropagation() {
    _isPropagationStopped = true;
  }
}
