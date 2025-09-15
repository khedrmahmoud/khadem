import 'package:test/test.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/queue_drivers/sync_queue_driver.dart';

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
  group('SyncQueueDriver', () {
    late SyncQueueDriver driver;
    late TestQueueJob testJob;
    late FailingQueueJob failingJob;

    setUp(() {
      driver = SyncQueueDriver();
      testJob = TestQueueJob('test');
      failingJob = FailingQueueJob('failing');
    });

    test('should execute job immediately on push', () async {
      await driver.push(testJob);

      expect(testJob.executed, isTrue);
    });

    test('should execute job with delay (delay is ignored in sync driver)', () async {
      await driver.push(testJob, delay: const Duration(seconds: 5));

      expect(testJob.executed, isTrue);
    });

    test('should handle job execution errors gracefully', () async {
      expect(() => driver.push(failingJob), throwsException);
    });

    test('should process method does nothing', () async {
      // Process should be a no-op for sync driver
      await expectLater(driver.process(), completes);
    });

    test('should handle multiple jobs sequentially', () async {
      final job1 = TestQueueJob('job1');
      final job2 = TestQueueJob('job2');
      final job3 = TestQueueJob('job3');

      await driver.push(job1);
      await driver.push(job2);
      await driver.push(job3);

      expect(job1.executed, isTrue);
      expect(job2.executed, isTrue);
      expect(job3.executed, isTrue);
    });

    test('should handle jobs with different execution times', () async {
      final slowJob = SlowQueueJob('slow');
      final fastJob = TestQueueJob('fast');

      final startTime = DateTime.now();

      await driver.push(slowJob);
      await driver.push(fastJob);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(slowJob.executed, isTrue);
      expect(fastJob.executed, isTrue);
      expect(duration.inMilliseconds, greaterThanOrEqualTo(100)); // At least 100ms for slow job
    });
  });
}

class SlowQueueJob extends QueueJob {
  final String name;
  bool executed = false;

  SlowQueueJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    // Simulate slow work
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}