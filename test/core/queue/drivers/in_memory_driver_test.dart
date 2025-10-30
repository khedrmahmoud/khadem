import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/drivers/base_driver.dart';
import 'package:khadem/src/core/queue/drivers/in_memory_driver.dart';
import 'package:khadem/src/core/queue/metrics/index.dart';
import 'package:test/test.dart';

// Test job implementation
class TestJob extends QueueJob {
  final String name;
  bool executed = false;
  dynamic result;

  TestJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    result = 'completed';
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class FailingJob extends QueueJob {
  final String name;

  FailingJob(this.name);

  @override
  Future<void> handle() async {
    throw Exception('Job failed: $name');
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('InMemoryDriver', () {
    late InMemoryDriver driver;
    late QueueMetrics metrics;

    setUp(() {
      metrics = QueueMetrics();
      driver = InMemoryDriver(
        config: const DriverConfig(
          name: 'test-memory',
          useDLQ: false,
        ),
        metrics: metrics,
      );
    });

    tearDown(() {
      driver.clear();
    });

    test('should push and process jobs immediately', () async {
      final job = TestJob('test-job');
      await driver.push(job);

      expect(driver.pendingJobsCount, equals(1));
      expect(job.executed, isFalse);

      await driver.process();

      expect(job.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should handle delayed jobs', () async {
      final job = TestJob('delayed-job');
      await driver.push(job, delay: const Duration(milliseconds: 100));

      expect(driver.pendingJobsCount, equals(1));

      // Process before delay - job should not execute
      await driver.process();
      expect(job.executed, isFalse);

      // Wait for delay and process again
      await Future.delayed(const Duration(milliseconds: 150));
      await driver.process();

      expect(job.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should process multiple jobs in order', () async {
      final job1 = TestJob('job1');
      final job2 = TestJob('job2');
      final job3 = TestJob('job3');

      await driver.push(job1);
      await driver.push(job2);
      await driver.push(job3);

      expect(driver.pendingJobsCount, equals(3));

      // Process each job
      while (driver.pendingJobsCount > 0) {
        await driver.process();
      }

      expect(job1.executed, isTrue);
      expect(job2.executed, isTrue);
      expect(job3.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should track metrics when enabled', () async {
      final job = TestJob('metrics-job');
      await driver.push(job);
      await driver.process();

      expect(metrics.totalQueued, equals(1));
      expect(metrics.totalCompleted, equals(1));
      expect(metrics.totalFailed, equals(0));
    });

    test('should handle job failures', () async {
      final job = FailingJob('fail-job');
      await driver.push(job);

      expect(driver.pendingJobsCount, equals(1));

      await driver.process();

      // Failed job remains in queue (for potential retry)
      expect(driver.pendingJobsCount, equals(1));
    });

    test('should clear all jobs', () async {
      await driver.push(TestJob('job1'));
      await driver.push(TestJob('job2'));
      await driver.push(TestJob('job3'));

      expect(driver.pendingJobsCount, equals(3));

      driver.clear();

      expect(driver.pendingJobsCount, equals(0));
    });

    test('should handle concurrent processing', () async {
      final jobs = List.generate(10, (i) => TestJob('job-$i'));

      for (final job in jobs) {
        await driver.push(job);
      }

      expect(driver.pendingJobsCount, equals(10));

      // Process all jobs
      while (driver.pendingJobsCount > 0) {
        await driver.process();
      }

      for (final job in jobs) {
        expect(job.executed, isTrue);
      }
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should support zero delay', () async {
      final job = TestJob('zero-delay');
      await driver.push(job, delay: Duration.zero);

      expect(driver.pendingJobsCount, equals(1));

      await driver.process();

      expect(job.executed, isTrue);
      expect(driver.pendingJobsCount, equals(0));
    });

    test('should handle negative delay as immediate', () async {
      final job = TestJob('negative-delay');
      await driver.push(job, delay: const Duration(milliseconds: -100));

      await driver.process();

      expect(job.executed, isTrue);
    });

    test('should maintain correct pending count with mixed delays', () async {
      final immediate = TestJob('immediate');
      final delayed = TestJob('delayed');

      await driver.push(immediate);
      await driver.push(delayed, delay: const Duration(seconds: 1));

      expect(driver.pendingJobsCount, equals(2));

      await driver.process();

      expect(immediate.executed, isTrue);
      expect(delayed.executed, isFalse);
      expect(driver.pendingJobsCount, equals(1));
    });
  });

  group('InMemoryDriver - Performance', () {
    test('should handle high volume jobs', () async {
      final driver = InMemoryDriver(
        config: const DriverConfig(name: 'perf-test'),
      );

      const jobCount = 1000;
      final jobs = List.generate(jobCount, (i) => TestJob('job-$i'));

      final pushStart = DateTime.now();
      for (final job in jobs) {
        await driver.push(job);
      }
      final pushDuration = DateTime.now().difference(pushStart);

      expect(driver.pendingJobsCount, equals(jobCount));

      final processStart = DateTime.now();
      // Process all jobs
      while (driver.pendingJobsCount > 0) {
        await driver.process();
      }
      final processDuration = DateTime.now().difference(processStart);

      for (final job in jobs) {
        expect(job.executed, isTrue);
      }

      print('Push $jobCount jobs: ${pushDuration.inMilliseconds}ms');
      print('Process $jobCount jobs: ${processDuration.inMilliseconds}ms');

      // Should complete within reasonable time (< 30 seconds for 1000 jobs)
      // Note: Each job has a 10ms delay, so 1000 jobs = ~10 seconds minimum
      expect(
        processDuration.inSeconds,
        lessThan(30),
        reason:
            'Processing 1000 jobs took ${processDuration.inSeconds}s, expected < 30s',
      );
    });
  });
}
