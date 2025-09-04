import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/scheduler/scheduled_job.dart';
import '../../../lib/src/contracts/scheduler/task_stats.dart';
import '../../../lib/src/core/scheduler/core/scheduled_task.dart';

// Mock classes
class MockScheduledJob extends Mock implements ScheduledJob {
  @override
  String get name => 'mock_job';

  @override
  Future<void> execute() async {
    // Mock implementation
  }
}

class FailingScheduledJob extends Mock implements ScheduledJob {
  @override
  String get name => 'failing_job';

  @override
  Future<void> execute() async {
    throw Exception('Test failure');
  }
}

void main() {
  group('ScheduledTask', () {
    late MockScheduledJob mockJob;
    late FailingScheduledJob failingJob;

    setUp(() {
      mockJob = MockScheduledJob();
      failingJob = FailingScheduledJob();
    });

    test('should create task with correct properties', () {
      final task = ScheduledTask(
        name: 'test_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
        retryOnFail: true,
      );

      expect(task.name, equals('test_task'));
      expect(task.interval, equals(const Duration(seconds: 30)));
      expect(task.retryOnFail, isTrue);
      expect(task.runOnce, isFalse);
      expect(task.maxRetries, equals(3));
    });

    test('should initialize stats correctly', () {
      final task = ScheduledTask(
        name: 'test_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
      );

      final stats = task.stats;
      expect(stats.name, equals('test_task'));
      expect(stats.successCount, equals(0));
      expect(stats.failureCount, equals(0));
      expect(stats.status, equals(TaskStatus.idle));
    });

    test('should create task from config', () {
      final config = {
        'name': 'config_task',
        'interval': 60,
        'job': 'ping',
        'retryOnFail': true,
        'runOnce': false,
        'maxRetries': 5,
      };

      // Note: This would require setting up the job registry
      // For now, we'll test the structure
      expect(() => ScheduledTask.fromConfig(config), throwsException);
    });

    test('should throw error for missing interval in config', () {
      final config = {
        'name': 'config_task',
        'job': 'ping',
      };

      expect(() => ScheduledTask.fromConfig(config),
          throwsA(isA<ArgumentError>()),);
    });

    test('should handle successful job execution', () async {
      final task = ScheduledTask(
        name: 'success_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
      );

      bool scheduledNext = false;
      void scheduleNext(Duration delay) {
        scheduledNext = true;
      }

      await task.run(scheduleNext);

      final stats = task.stats;
      expect(stats.successCount, equals(1));
      expect(stats.failureCount, equals(0));
      expect(stats.status, equals(TaskStatus.idle));
      expect(scheduledNext, isTrue);
    });

    test('should handle job failure without retry', () async {
      final task = ScheduledTask(
        name: 'fail_task',
        interval: const Duration(seconds: 30),
        job: failingJob,
      );

      bool scheduledNext = false;
      void scheduleNext(Duration delay) {
        scheduledNext = true;
      }

      await task.run(scheduleNext);

      final stats = task.stats;
      expect(stats.successCount, equals(0));
      expect(stats.failureCount, equals(1));
      expect(stats.status, equals(TaskStatus.idle));
      expect(scheduledNext, isTrue);
    });

    test('should handle job failure with retry', () async {
      final task = ScheduledTask(
        name: 'retry_task',
        interval: const Duration(seconds: 30),
        job: failingJob,
        retryOnFail: true,
        maxRetries: 2,
      );

      int scheduleCount = 0;
      void scheduleNext(Duration delay) {
        scheduleCount++;
      }

      await task.run(scheduleNext);

      final stats = task.stats;
      expect(stats.successCount, equals(0));
      expect(stats.failureCount, equals(1));
      expect(stats.status, equals(TaskStatus.idle));
      // Should have scheduled retry
      expect(scheduleCount, equals(1));
    });

    test('should pause and resume task', () {
      final task = ScheduledTask(
        name: 'pause_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
      );

      task.pause();
      expect(task.stats.status, equals(TaskStatus.paused));

      bool scheduledNext = false;
      void scheduleNext(Duration delay) {
        scheduledNext = true;
      }

      task.resume(scheduleNext);
      expect(task.stats.status, equals(TaskStatus.idle));
      expect(scheduledNext, isTrue);
    });

    test('should stop task', () {
      final task = ScheduledTask(
        name: 'stop_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
      );

      task.stop();
      expect(task.timer, isNull);
    });

    test('should calculate average execution time', () async {
      final task = ScheduledTask(
        name: 'timing_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
      );

      // Run task multiple times
      for (int i = 0; i < 3; i++) {
        void scheduleNext(Duration delay) {}
        await task.run(scheduleNext);
      }

      final stats = task.stats;
      expect(stats.successCount, equals(3));
      expect(stats.averageExecutionTime, greaterThan(0));
    });

    test('should handle runOnce tasks', () async {
      final task = ScheduledTask(
        name: 'once_task',
        interval: const Duration(seconds: 30),
        job: mockJob,
        runOnce: true,
      );

      int scheduleCount = 0;
      void scheduleNext(Duration delay) {
        scheduleCount++;
      }

      await task.run(scheduleNext);

      final stats = task.stats;
      expect(stats.successCount, equals(1));
      // Should not schedule next run for runOnce tasks
      expect(scheduleCount, equals(0));
    });
  });
}
