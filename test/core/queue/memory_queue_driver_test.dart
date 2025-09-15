import 'package:test/test.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/queue_drivers/memory_queue_driver.dart';

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

void main() {
  group('MemoryQueueDriver', () {
    late MemoryQueueDriver driver;
    late TestQueueJob testJob;
    late FailingQueueJob failingJob;

    setUp(() {
      driver = MemoryQueueDriver();
      testJob = TestQueueJob('test');
      failingJob = FailingQueueJob('failing');
    });

    tearDown(() {
      driver.clear();
    });

    test('should push job without delay and store for processing', () async {
      await driver.push(testJob);

      expect(testJob.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));

      // Small delay to ensure job is ready
      await Future.delayed(const Duration(milliseconds: 10));
      // Process the job
      await driver.process();

      expect(testJob.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should push job with delay and not execute immediately', () async {
      await driver.push(testJob, delay: const Duration(seconds: 1));

      expect(testJob.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));
    });

    test('should process delayed jobs when they become ready', () async {
      await driver.push(testJob, delay: const Duration(milliseconds: 100));

      expect(testJob.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));

      // Wait for the delay to pass
      await Future.delayed(const Duration(milliseconds: 150));

      await driver.process();

      expect(testJob.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should handle multiple delayed jobs', () async {
      final job1 = TestQueueJob('job1');
      final job2 = TestQueueJob('job2');
      final job3 = TestQueueJob('job3');

      await driver.push(job1, delay: const Duration(milliseconds: 50));
      await driver.push(job2, delay: const Duration(milliseconds: 100));
      await driver.push(job3, delay: const Duration(milliseconds: 150));

      expect(driver.pendingJobsCount, equals(3));

      // Wait and process
      await Future.delayed(const Duration(milliseconds: 200));
      await driver.process();

      expect(job1.executed, isTrue);
      expect(job2.executed, isTrue);
      expect(job3.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should only process jobs that are ready', () async {
      final readyJob = TestQueueJob('ready');
      final delayedJob = TestQueueJob('delayed');

      await driver.push(readyJob); // No delay
      await driver.push(delayedJob, delay: const Duration(seconds: 1));

      expect(readyJob.executed, isFalse);
      expect(delayedJob.executed, isFalse);
      expect(driver.pendingJobsCount, equals(2));

      // Small delay to ensure job is ready
      await Future.delayed(const Duration(milliseconds: 10));
      await driver.process();

      expect(readyJob.executed, isTrue); // Should be processed
      expect(delayedJob.executed, isFalse); // Still not ready
      expect(driver.pendingJobsCount, equals(1));
    });

    test('should handle job execution errors gracefully', () async {
      await driver.push(failingJob);

      expect(driver.pendingJobsCount, equals(1));

      // Should not throw when processing failing job, but job stays in queue
      await expectLater(driver.process(), completes);

      // Job should remain in queue after failure (current behavior)
      expect(driver.pendingJobsCount, equals(1));
    });

    test('should clear all pending jobs', () async {
      await driver.push(testJob, delay: const Duration(seconds: 1));
      await driver.push(TestQueueJob('job2'), delay: const Duration(seconds: 1));

      expect(driver.pendingJobsCount, equals(2));

      driver.clear();

      expect(driver.pendingJobsCount, equals(0));
    });

    test('should handle process being called multiple times', () async {
      final job1 = TestQueueJob('job1');
      final job2 = TestQueueJob('job2');

      await driver.push(job1, delay: const Duration(milliseconds: 50));
      await driver.push(job2, delay: const Duration(milliseconds: 100));

      // Process before jobs are ready
      await driver.process();
      expect(job1.executed, isFalse);
      expect(job2.executed, isFalse);

      // Wait and process again
      await Future.delayed(const Duration(milliseconds: 120));
      await driver.process();

      expect(job1.executed, isTrue);
      expect(job2.executed, isTrue);
    });

    test('should handle zero delay jobs', () async {
      final job = TestQueueJob('zero-delay');

      await driver.push(job, delay: Duration.zero);

      expect(job.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));

      // Small delay to ensure job is ready
      await Future.delayed(const Duration(milliseconds: 10));
      await driver.process();

      expect(job.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should handle negative delay as zero delay', () async {
      final job = TestQueueJob('negative-delay');

      await driver.push(job, delay: const Duration(milliseconds: -100));

      expect(job.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));

      await driver.process();

      expect(job.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should maintain correct pending count with mixed delays', () async {
      final immediateJob = TestQueueJob('immediate');
      final delayedJob1 = TestQueueJob('delayed1');
      final delayedJob2 = TestQueueJob('delayed2');

      await driver.push(immediateJob); // No delay
      await driver.push(delayedJob1, delay: const Duration(milliseconds: 100));
      await driver.push(delayedJob2, delay: const Duration(milliseconds: 200));

      expect(immediateJob.executed, isFalse);
      expect(delayedJob1.executed, isFalse);
      expect(delayedJob2.executed, isFalse);
      expect(driver.pendingJobsCount, equals(3));

      // Process all ready jobs (immediate job should be ready)
      await Future.delayed(const Duration(milliseconds: 10));
      await driver.process();

      expect(immediateJob.executed, isTrue);
      expect(delayedJob1.executed, isFalse);
      expect(delayedJob2.executed, isFalse);
      expect(driver.pendingJobsCount, equals(2));

      // Process first delayed job
      await Future.delayed(const Duration(milliseconds: 100));
      await driver.process();

      expect(delayedJob1.executed, isTrue);
      expect(delayedJob2.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));

      // Process second delayed job
      await Future.delayed(const Duration(milliseconds: 120));
      await driver.process();

      expect(delayedJob2.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });
  });
}