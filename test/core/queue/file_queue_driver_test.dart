import 'dart:io';

import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/queue_drivers/file_queue_driver.dart';
import 'package:test/test.dart';

// Test job implementation
class TestQueueJob extends QueueJob {
  final String name;
  bool executed = false;

  TestQueueJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    // Simulate some work
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class FailingQueueJob extends QueueJob {
  final String name;

  FailingQueueJob(this.name);

  @override
  Future<void> handle() async {
    throw Exception('Job failed');
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class SlowQueueJob extends QueueJob {
  final String name;
  bool executed = false;

  SlowQueueJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('FileQueueDriver', () {
    late FileQueueDriver driver;
    late Directory tempDir;
    late String queuePath;
    late TestQueueJob testJob;
    late FailingQueueJob failingJob;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_queue_test_');
      queuePath = '${tempDir.path}/test_queue.json';
      driver = FileQueueDriver(queuePath: queuePath);
      testJob = TestQueueJob('test');
      failingJob = FailingQueueJob('failing');
    });

    tearDown(() async {
      await driver.clear();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should push job and persist to file', () async {
      await driver.push(testJob);

      expect(testJob.executed, isFalse);

      // Check file exists and contains job
      final file = File(queuePath);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, isNotEmpty);

      // File should contain the job data
      expect(content.contains('TestQueueJob'), isTrue);
      expect(content.contains('test'), isTrue);
    });

    test('should process jobs from file', () async {
      await driver.push(testJob);

      expect(testJob.executed, isFalse);

      await driver.process();

      // Since FileQueueDriver uses generic job wrapper, original job isn't executed
      // But the job should be removed from the file
      final file = File(queuePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        // File should be empty after processing
        expect(content, equals('[]'));
      }
    });

    test('should handle delayed jobs', () async {
      await driver.push(testJob, delay: const Duration(milliseconds: 100));

      expect(testJob.executed, isFalse);

      // Process before delay - job should not be processed (file unchanged)
      await driver.process();
      final file = File(queuePath);
      final content1 = await file.readAsString();
      expect(content1.contains('TestQueueJob'), isTrue); // Job still in file

      // Wait for delay and process again
      await Future.delayed(const Duration(milliseconds: 150));
      await driver.process();

      // Job should be processed and removed from file
      final content2 = await file.readAsString();
      expect(content2, equals('[]'));
    });

    test('should handle multiple jobs', () async {
      final job1 = TestQueueJob('job1');
      final job2 = TestQueueJob('job2');
      final job3 = TestQueueJob('job3');

      await driver.push(job1);
      await driver.push(job2);
      await driver.push(job3);

      expect(job1.executed, isFalse);
      expect(job2.executed, isFalse);
      expect(job3.executed, isFalse);

      await driver.process();

      // All jobs should be processed and file should be empty
      final file = File(queuePath);
      final content = await file.readAsString();
      expect(content, equals('[]'));
    });

    test('should handle job processing and file cleanup', () async {
      await driver.push(failingJob);

      // Process the job
      await driver.process();

      // Job should be processed and removed from file
      final file = File(queuePath);
      final content = await file.readAsString();
      expect(content, equals('[]'));
    });

    test('should persist jobs across driver instances', () async {
      // Push job with first driver instance
      await driver.push(testJob);
      expect(testJob.executed, isFalse);

      // Create new driver instance with same file
      final driver2 = FileQueueDriver(queuePath: queuePath);

      // Process with second driver
      await driver2.process();

      // Job should have been processed and file should be empty
      final file = File(queuePath);
      final content = await file.readAsString();
      expect(content, equals('[]'));
    });

    test('should clear all jobs', () async {
      await driver.push(testJob);
      await driver.push(TestQueueJob('job2'));

      final file = File(queuePath);
      expect(await file.exists(), isTrue);

      await driver.clear();

      final content = await file.readAsString();
      expect(content, equals('[]'));
    });

    test('should get correct pending jobs count', () async {
      expect(driver.pendingJobs, equals(0));

      await driver.push(testJob);
      expect(driver.pendingJobs, equals(1));

      await driver.push(TestQueueJob('job2'));
      expect(driver.pendingJobs, equals(2));

      await driver.process();
      expect(driver.pendingJobs, equals(0));
    });

    test('should get queue statistics', () async {
      final stats = driver.getStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['driver'], equals('file'));
      expect(stats['total_jobs'], equals(0));
      expect(stats['ready_jobs'], equals(0));
      expect(stats['scheduled_jobs'], equals(0));
      expect(stats['file_path'], equals(queuePath));

      await driver.push(testJob);
      await driver.push(
        TestQueueJob('delayed'),
        delay: const Duration(seconds: 1),
      );

      final statsWithJobs = driver.getStats();
      expect(statsWithJobs['total_jobs'], equals(2));
      expect(statsWithJobs['ready_jobs'], equals(1)); // immediate job
      expect(statsWithJobs['scheduled_jobs'], equals(1)); // delayed job
    });

    test('should handle file I/O errors gracefully', () async {
      // Create driver with invalid path
      final invalidDriver =
          FileQueueDriver(queuePath: '/invalid/path/queue.json');

      // Should not throw on push
      await expectLater(invalidDriver.push(testJob), completes);

      // Should not throw on process
      await expectLater(invalidDriver.process(), completes);
    });

    test('should handle empty or corrupted file', () async {
      final file = File(queuePath);
      await file.create(recursive: true);

      // Test with empty file
      await file.writeAsString('');
      await expectLater(driver.process(), completes);

      // Test with invalid JSON
      await file.writeAsString('invalid json');
      await expectLater(driver.process(), completes);
    });
  });
}
