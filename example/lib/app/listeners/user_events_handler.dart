import 'package:khadem/contracts.dart' show Dispatcher, Subscriber;
import 'package:khadem/khadem.dart' show Khadem;

import '../events/user_events.dart';
import '../jobs/send_user_notification_job.dart';

class UserEventsHandler implements Subscriber {
  @override
  void subscribe(Dispatcher dispatcher) {
    dispatcher.listenType(UserCreated, (event) async {
      await onCreated(event as UserCreated);
    });
    dispatcher.listenType(UserUpdated, (event) async {
      await onUpdated(event as UserUpdated);
    });
    dispatcher.listenType(UserDeleted, (event) async {
      await onDeleted(event as UserDeleted);
    });
  }

  Future<void> onCreated(UserCreated event) async {
    print('📥 User created: ${event.payload}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('New User Created'),
      delay: const Duration(seconds: 5),
    );
  }

  Future<void> onUpdated(UserUpdated event) async {
    print('✏️ User updated: ${event.payload}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('User Updated'),
      delay: const Duration(seconds: 5),
    );
  }

  Future<void> onDeleted(UserDeleted event) async {
    print('🗑️ User deleted: ${event.payload}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('User Deleted'),
      delay: const Duration(seconds: 5),
    );
  }
}
