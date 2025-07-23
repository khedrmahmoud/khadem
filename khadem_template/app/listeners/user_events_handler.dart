import 'package:khadem/khadem_dart.dart'
    show Khadem, EventMethod, EventSubscriberInterface;

import '../Jobs/send_user_notification_job.dart';

class UserEventsHandler implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: 'user.created',
          handler: (payload) async => await onCreated(payload),
        ),
        EventMethod(
          eventName: 'user.updated',
          handler: (payload) async => await onUpdated(payload),
        ),
        EventMethod(
          eventName: 'user.deleted',
          handler: (payload) async => await onDeleted(payload),
        ),
      ];

  Future onCreated(dynamic payload) async {
    print('📥 User created: ${payload.toJson()}');
    await Khadem.queue.dispatch(SendUserNotificationJob('New User Created'),
        delay: Duration(seconds: 5));
  }

  Future onUpdated(dynamic payload) async {
    print('✏️ User updated: ${payload.toJson()}');
    await Khadem.queue.dispatch(SendUserNotificationJob('User Updated'),
        delay: Duration(seconds: 5));
  }

  Future onDeleted(dynamic payload) async {
    print('🗑️ User deleted: ${payload.toJson()}');
    await Khadem.queue.dispatch(SendUserNotificationJob('User Deleted'),
        delay: Duration(seconds: 5));
  }
}
