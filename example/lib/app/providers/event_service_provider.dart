import 'package:khadem/khadem.dart' show ServiceProvider, registerSubscribers;

import '../listeners/user_events_handler.dart';

class EventServiceProvider extends ServiceProvider {
  @override
  void register(container) {
    final subscribers = [
      UserEventsHandler(),
      // add more subscribers here
    ];
    registerSubscribers(subscribers);
  }

  @override
  Future<void> boot(container) async {}
}
