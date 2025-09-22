import 'package:khadem/khadem.dart'
    show Khadem, EventMethod, EventSubscriberInterface;

import '../jobs/send_user_notification_job.dart';

class UserEventsHandler implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: 'user.created',
          handler: (payload) async => onCreated(payload),
        ),
        EventMethod(
          eventName: 'user.updated',
          handler: (payload) async => onUpdated(payload),
        ),
        EventMethod(
          eventName: 'user.deleted',
          handler: (payload) async => onDeleted(payload),
        ),
      ];

  Future onCreated(dynamic payload) async {
    print('📥 User created: ${payload.toJson()}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('New User Created'),
      delay: const Duration(seconds: 5),
    );
  }

  Future onUpdated(dynamic payload) async {
    print('✏️ User updated: ${payload.toJson()}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('User Updated'),
      delay: const Duration(seconds: 5),
    );
  }

  Future onDeleted(dynamic payload) async {
    print('🗑️ User deleted: ${payload.toJson()}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('User Deleted'),
      delay: const Duration(seconds: 5),
    );
  }
}
