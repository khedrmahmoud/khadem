import '../../contracts/events/event_system_interface.dart';

/// A single event handler method.
///
/// [EventMethod] is a class that represents a single event handler method.
/// It contains the event name, the handler function, the priority of the
/// handler, and whether the handler should be called only once.
///
/// [EventMethod] is used by [EventSubscriber] to register events.
class EventMethod {
  /// The name of the event this method is listening to.
  final String eventName;

  /// The handler function that will be called when the event is fired.
  final Future<void> Function(dynamic payload) handler;

  /// The priority of the handler.
  ///
  /// The priority determines the order in which the event handlers are
  /// executed. The handlers with the highest priority are executed first.
  final EventPriority priority;

  /// Whether the handler should be called only once.
  ///
  /// If [once] is `true`, the handler will be executed only once and then
  /// removed from the event listeners.
  final bool once;

  /// Creates a new [EventMethod] instance.
  ///
  /// The [eventName] and [handler] arguments are required.
  /// The [priority] argument defaults to [EventPriority.normal].
  /// The [once] argument defaults to `false`.
  EventMethod({
    required this.eventName,
    required this.handler,
    this.priority = EventPriority.normal,
    this.once = false,
  });
}
