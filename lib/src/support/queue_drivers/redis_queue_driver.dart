import 'dart:convert';
import 'package:redis/redis.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import '../../infrastructure/queue/job_registry.dart';

class RedisQueueDriver implements QueueDriver {
  final String channel = 'jobs';

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final conn = RedisConnection();
    final command = await conn.connect('localhost', 6379);

    await command.send_object([
      'PUBLISH',
      channel,
      jsonEncode({
        'job': job.toJson(), // يجب أن تكون job قابلة للتشفير
        'scheduledAt':
            DateTime.now().add(delay ?? Duration.zero).toIso8601String(),
      }),
    ]);
  }

  @override
  Future<void> process() async {
    final conn = RedisConnection();
    final command = await conn.connect('localhost', 6379);
    final pubsub = PubSub(command);

    pubsub.subscribe([channel]);

    pubsub.getStream().listen((message) async {
      // Format: [message, channel, payload]
      if (message.length >= 3 && message[0] == 'message') {
        final raw = jsonDecode(message[2]);
        final job = QueueJobRegistry.fromJson(raw['job']);
        final scheduled = DateTime.parse(raw['scheduledAt']);

        if (scheduled.isBefore(DateTime.now())) {
          await job.handle();
        }
      }
    });
  }
}
