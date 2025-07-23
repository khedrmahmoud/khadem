import 'dart:convert';
import 'dart:io';

import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import '../../application/khadem.dart';
import '../../infrastructure/queue/job_registry.dart';

class FileQueueDriver implements QueueDriver {
  final String filePath = 'storage/queue/jobs.json';

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final file = File(filePath);
    await file.create(recursive: true);
    final data = {
      'job': job.toJson(), // يجب أن تدعم QueueJob toJson()
      'delay': (delay ?? Duration.zero).inMilliseconds,
      'scheduledAt':
          DateTime.now().add(delay ?? Duration.zero).toIso8601String(),
    };

    List jobs = [];
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        jobs = decoded;
      }
    } catch (_) {
      jobs = [];
    }

    jobs.add(data);
    file.writeAsStringSync(jsonEncode(jobs));
  }

  @override
  Future<void> process() async {
    final file = File(filePath);
    if (!file.existsSync()) return;

    List jobs = [];
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        jobs = decoded;
      }
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    final remaining = [];

    for (final raw in jobs) {
      try {
        final scheduledAt = DateTime.parse(raw['scheduledAt']);
        if (scheduledAt.isBefore(now)) {
          final job = QueueJobRegistry.fromJson(raw['job']);
          await job.handle();
        } else {
          remaining.add(raw);
        }
      } catch (e) {
        Khadem.logger.error('Failed to process job: $e');
      }
    }

    await file.writeAsString(jsonEncode(remaining), flush: true);
  }
}
