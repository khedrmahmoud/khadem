import 'package:khadem/khadem_dart.dart'
    show ServiceProvider, registerSubscribers;

import '../jobs/send_user_notification_job.dart';
import '../listeners/user_events_handler.dart';

class EventServiceProvider extends ServiceProvider {
  @override
  void register( container) {
    final subscribers = [
      UserEventsHandler(),
      // add more subscribers here
    ];
    registerSubscribers(subscribers);
    // 
    SendUserNotificationJob('').register();
  }

  @override
  Future<void> boot( container) async {}
}
