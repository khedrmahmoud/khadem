import 'package:khadem/contracts.dart' show QueueJob;

class SendUserNotificationJob extends QueueJob {
  final String event;

  SendUserNotificationJob(this.event) {}

  @override
  Future<void> handle() async {
    print('🔔 Notification sent for user: $event');
  }
}
