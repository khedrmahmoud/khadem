import '../../contracts/events/event_subscriber_interface.dart';
import '../../application/khadem.dart';

void registerSubscribers(List<EventSubscriberInterface> subscribers) {
  for (final subscriber in subscribers) {
    for (final method in subscriber.getEventHandlers()) {
      Khadem.eventBus.on(
        method.eventName,
        method.handler,
        priority: method.priority,
        once: method.once,
        subscriber: subscriber,
      );
    }
  }
}
