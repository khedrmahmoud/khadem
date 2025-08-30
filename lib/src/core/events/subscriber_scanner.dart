import '../../application/khadem.dart';
import '../../contracts/events/event_subscriber_interface.dart';
import '../../contracts/events/event_system_interface.dart';

/// Utility for registering event subscribers with the global event system.
///
/// This function provides a convenient way to register multiple event subscribers
/// at once, automatically registering all their event handlers with the global
/// event bus. It's typically used during application initialization to set up
/// all event-driven components.
///
/// The function iterates through each subscriber and registers all their event
/// handlers using the global Khadem event bus. Each handler is registered with
/// its specified priority and one-time execution settings.
///
/// Example usage:
/// ```dart
/// class UserEventHandler implements EventSubscriberInterface {
///   @override
///   List<EventMethod> getEventHandlers() => [
///     EventMethod(
///       eventName: 'user.created',
///       handler: (user) async => print('User created: $user'),
///       priority: EventPriority.normal,
///     ),
///   ];
/// }
///
/// // Register the subscriber
/// registerSubscribers([UserEventHandler()]);
/// ```
///
/// [subscribers] - A list of event subscriber instances to register
/// [eventSystem] - Optional event system instance to use (defaults to global Khadem event bus)
void registerSubscribers(List<EventSubscriberInterface> subscribers,
    [EventSystemInterface? eventSystem]) {
  final bus = eventSystem ?? Khadem.eventBus;
  for (final subscriber in subscribers) {
    for (final method in subscriber.getEventHandlers()) {
      bus.on(
        method.eventName,
        method.handler,
        priority: method.priority,
        once: method.once,
        subscriber: subscriber,
      );
    }
  }
}
