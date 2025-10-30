import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/drivers/base_driver.dart';
import 'package:khadem/src/core/queue/drivers/in_memory_driver.dart';
import 'package:khadem/src/core/queue/worker.dart';
import 'package:test/test.dart';

// Test job implementation
class TestJob extends QueueJob {
  final String name;
  bool executed = false;

  TestJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class SlowJob extends QueueJob {
  final Duration delay;
  bool executed = false;

  SlowJob(this.delay);

  @override
  Future<void> handle() async {
    executed = true;
    await Future.delayed(delay);
  }

  @override
  Map<String, dynamic> toJson() => {'delay': delay.inMilliseconds};
}

void main() {
  group('QueueWorker', () {
    late InMemoryDriver driver;

    setUp(() {
      driver = InMemoryDriver(
        config: const DriverConfig(name: 'test-worker'),
      );
    });

    test('should process jobs with delay', () async {
      final job1 = TestJob('job1');
      final job2 = TestJob('job2');

      await driver.push(job1);
      await driver.push(job2);

      final worker = QueueWorker(
        driver,
        const QueueWorkerConfig(
          maxJobs: 2,
          delay: Duration(milliseconds: 100),
        ),
      );

      await worker.start();

      expect(job1.executed, isTrue);
      expect(job2.executed, isTrue);
    });

    test('should stop after max jobs', () async {
      for (int i = 0; i < 10; i++) {
        await driver.push(TestJob('job$i'));
      }

      final worker = QueueWorker(
        driver,
        const QueueWorkerConfig(
          maxJobs: 5,
          delay: Duration(milliseconds: 10),
        ),
      );

      await worker.start();

      // Should still have 5 jobs left
      expect(driver.pendingJobsCount, equals(5));
    });

    test('should respect timeout', () async {
      final slowJob = SlowJob(const Duration(seconds: 2));
      await driver.push(slowJob);

      final worker = QueueWorker(
        driver,
        const QueueWorkerConfig(
          timeout: Duration(milliseconds: 100),
          delay: Duration(milliseconds: 10),
          maxJobs: 1,
        ),
      );

      await worker.start();

      // Job might not complete due to timeout
      expect(worker.isRunning, isFalse);
    });

    // Note: Callback tests (onJobStart, onJobComplete, onJobError) are not included
    // because the current worker architecture doesn't have visibility into individual
    // jobs - it only calls driver.process(). Callbacks would need to be implemented
    // at the driver level for per-job notifications.

    test('should support graceful shutdown', () async {
      for (int i = 0; i < 5; i++) {
        await driver.push(TestJob('job$i'));
      }

      final worker = QueueWorker(
        driver,
        const QueueWorkerConfig(
          delay: Duration(milliseconds: 100),
          gracefulShutdownTimeout: Duration(seconds: 2),
        ),
      );

      // Start worker in background
      unawaited(worker.start());

      // Let it process a few jobs
      await Future.delayed(const Duration(milliseconds: 200));

      // Request shutdown
      await worker.stop();

      expect(worker.isRunning, isFalse);
    });

    test('should track running job count', () async {
      final worker = QueueWorker(
        driver,
        const QueueWorkerConfig(
          delay: Duration(milliseconds: 10),
        ),
      );

      expect(worker.runningJobCount, equals(0));
    });
  });

  group('QueueWorkerPool', () {
    late InMemoryDriver driver;

    setUp(() {
      driver = InMemoryDriver(
        config: const DriverConfig(name: 'test-pool'),
      );
    });

    test('should start multiple workers', () async {
      for (int i = 0; i < 20; i++) {
        await driver.push(TestJob('job$i'));
      }

      final pool = QueueWorkerPool(
        driver: driver,
        config: const QueueWorkerConfig(
          delay: Duration(milliseconds: 10),
        ),
      );

      await pool.start();

      // Let workers process
      await Future.delayed(const Duration(seconds: 2));

      await pool.stop();

      // Most jobs should be processed
      expect(driver.pendingJobsCount, lessThan(10));
    });

    test('should get pool stats', () async {
      final pool = QueueWorkerPool(
        driver: driver,
        workerCount: 3,
      );

      await pool.start();

      final stats = pool.getStats();

      expect(stats['workerCount'], equals(3));
      expect(stats['activeWorkers'], greaterThanOrEqualTo(0));

      await pool.stop();
    });

    test('should scale workers dynamically', () async {
      for (int i = 0; i < 50; i++) {
        await driver.push(TestJob('job$i'));
      }

      final pool = QueueWorkerPool(
        driver: driver,
        workerCount: 2,
      );

      await pool.start();

      // Scale up
      await pool.scale(4);

      await Future.delayed(const Duration(milliseconds: 500));

      // Scale down
      await pool.scale(2);

      await pool.stop();
    });

    test('should handle graceful shutdown', () async {
      for (int i = 0; i < 10; i++) {
        await driver.push(SlowJob(const Duration(milliseconds: 100)));
      }

      final pool = QueueWorkerPool(
        driver: driver,
        workerCount: 2,
      );

      await pool.start();

      await Future.delayed(const Duration(milliseconds: 200));

      await pool.stop();

      expect(pool.isRunning, isFalse);
    });
  });
}

// Helper for background tasks
void unawaited(Future<void> future) {
  future.catchError((error) {
    // Ignore errors
  });
}
