import '../../core/events/event_method.dart';

/// Interface for classes that want to subscribe to events using handler methods.
///
/// Used to group event logic inside a single class.
abstract class EventSubscriberInterface {
  /// Returns a list of event handler definitions in this subscriber.
  List<EventMethod> getEventHandlers();
}
