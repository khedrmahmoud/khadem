import 'package:khadem/khadem_dart.dart' show QueueJob;

class SendUserNotificationJob extends QueueJob {
  final String event;

  SendUserNotificationJob(this.event) {}

  @override
  Future<void> handle() async {
    print('🔔 Notification sent for user: $event');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': runtimeType.toString(),
      'event': event,
    };
  }

  @override
  QueueJob fromJson(Map<String, dynamic> json) {
    return SendUserNotificationJob(json['event']);
  }
}
