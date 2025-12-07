import 'package:khadem/khadem.dart';
 import '../jobs/send_user_notification_job.dart';
import '../models/user.dart';

class UserEventsHandler implements Subscriber {
  @override
  void subscribe(Dispatcher dispatcher) {
    dispatcher.listen<ModelCreated<User>>(onCreated);
    dispatcher.listen<ModelUpdated<User>>(onUpdated);
    dispatcher.listen<ModelDeleted<User>>(onDeleted);
  }

  Future<void> onCreated(ModelCreated<User> event) async {
    print('📥 User created: ${event.model.toJson()}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('New User Created'),
      delay: const Duration(seconds: 5),
    );
  }

  Future<void> onUpdated(ModelUpdated<User> event) async {
    print('✏️ User updated: ${event.model.toJson()}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('User Updated'),
      delay: const Duration(seconds: 5),
    );
  }

  Future<void> onDeleted(ModelDeleted<User> event) async {
    print('🗑️ User deleted: ${event.model.toJson()}');
    await Khadem.queue.dispatch(
      SendUserNotificationJob('User Deleted'),
      delay: const Duration(seconds: 5),
    );
  }
}
