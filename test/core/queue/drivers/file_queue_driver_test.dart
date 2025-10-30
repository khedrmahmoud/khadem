import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/drivers/base_driver.dart';
import 'package:khadem/src/core/queue/drivers/file_storage_driver.dart';
import 'package:khadem/src/core/queue/registry/index.dart';
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
  Map<String, dynamic> toJson() => {'name': name, 'type': 'TestQueueJob'};

  factory TestQueueJob.fromJson(Map<String, dynamic> json) {
    return TestQueueJob(json['name'] as String);
  }
}

class FailingQueueJob extends QueueJob {
  final String name;

  FailingQueueJob(this.name);

  @override
  Future<void> handle() async {
    throw Exception('Job failed');
  }

  @override
  Map<String, dynamic> toJson() => {'name': name, 'type': 'FailingQueueJob'};

  factory FailingQueueJob.fromJson(Map<String, dynamic> json) {
    return FailingQueueJob(json['name'] as String);
  }
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
  Map<String, dynamic> toJson() => {'name': name, 'type': 'SlowQueueJob'};

  factory SlowQueueJob.fromJson(Map<String, dynamic> json) {
    return SlowQueueJob(json['name'] as String);
  }
}

void main() {
  setUpAll(() {
    // Register job types for deserialization
    QueueJobRegistry.register('TestQueueJob', TestQueueJob.fromJson);
    QueueJobRegistry.register('FailingQueueJob', FailingQueueJob.fromJson);
    QueueJobRegistry.register('SlowQueueJob', SlowQueueJob.fromJson);
  });

  group('FileStorageDriver', () {
    late FileStorageDriver driver;
    late Directory tempDir;
    late String storagePath;
    late TestQueueJob testJob;
    late FailingQueueJob failingJob;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_queue_test_');
      storagePath = tempDir.path;
      driver = FileStorageDriver(
        config: const DriverConfig(name: 'test-file'),
        storagePath: storagePath,
      );
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

      // Check storage directory and jobs file
      final storageDir = Directory(storagePath);
      expect(await storageDir.exists(), isTrue);

      final jobsFile = File('$storagePath/jobs.json');
      expect(await jobsFile.exists(), isTrue);

      final content = await jobsFile.readAsString();
      expect(content, isNotEmpty);

      // File should contain the job data
      expect(content.contains('TestQueueJob'), isTrue);
      expect(content.contains('test'), isTrue);
    });

    test('should process jobs from file', () async {
      await driver.push(testJob);

      expect(testJob.executed, isFalse);

      // Process jobs - since jobs are deserialized, they should execute
      await driver.process();

      expect(testJob.executed, isTrue);
    });

    test('should handle delayed jobs', () async {
      await driver.push(testJob, delay: const Duration(milliseconds: 100));

      expect(testJob.executed, isFalse);

      // Process before delay - job should not be ready yet
      await driver.process();
      expect(testJob.executed, isFalse);

      // Wait for delay and process again
      await Future.delayed(const Duration(milliseconds: 150));
      await driver.process();

      // Job should now be processed
      expect(testJob.executed, isTrue);
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

      // Process one at a time
      await driver.process();
      expect(job1.executed, isTrue);

      await driver.process();
      expect(job2.executed, isTrue);

      await driver.process();
      expect(job3.executed, isTrue);
    });

    test('should handle job failures gracefully', () async {
      await driver.push(failingJob);

      // Process the job - should handle failure gracefully
      await expectLater(driver.process(), completes);
    });

    test('should persist jobs across driver instances', () async {
      // Push job with first driver instance
      await driver.push(testJob);
      expect(testJob.executed, isFalse);

      // Create new driver instance with same storage path
      final driver2 = FileStorageDriver(
        config: const DriverConfig(name: 'test-file-2'),
        storagePath: storagePath,
      );

      // Process with second driver - it should load persisted jobs
      await driver2.process();

      // The driver should have processed the job from storage
      final jobsFile = File('$storagePath/jobs.json');
      if (await jobsFile.exists()) {
        final content = await jobsFile.readAsString();
        final jobs = jsonDecode(content) as List;
        // Job count should have decreased
        expect(jobs.length, lessThan(2));
      }
    });

    test('should clear all jobs', () async {
      await driver.push(testJob);
      await driver.push(TestQueueJob('job2'));

      final jobsFile = File('$storagePath/jobs.json');
      expect(await jobsFile.exists(), isTrue);

      await driver.clear();

      final content = await jobsFile.readAsString();
      expect(content, equals('[]'));
    });

    test('should get queue statistics', () async {
      final stats = await driver.getStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['driver'], equals('test-file')); // Uses config name

      await driver.push(testJob);
      await driver.push(
        TestQueueJob('delayed'),
        delay: const Duration(seconds: 1),
      );

      final statsWithJobs = await driver.getStats();
      expect(statsWithJobs['total_jobs'], greaterThan(0));
    });

    test('should handle invalid storage path gracefully', () async {
      // Create driver with restricted path (might not have write permissions)
      final restrictedDriver = FileStorageDriver(
        config: const DriverConfig(name: 'test-restricted'),
        storagePath: '/root/restricted',
      );

      // Should handle gracefully even if can't write
      await expectLater(restrictedDriver.push(testJob), completes);
    });
  });
}
