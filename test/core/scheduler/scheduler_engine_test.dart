import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/scheduler/scheduled_job.dart';
import '../../../lib/src/contracts/scheduler/task_stats.dart';
import '../../../lib/src/core/scheduler/core/scheduled_task.dart';
import '../../../lib/src/core/scheduler/scheduler.dart';

// Mock classes
class MockScheduledJob extends Mock implements ScheduledJob {
  @override
  String get name => 'mock_job';

  @override
  Future<void> execute() async {
    // Mock implementation
  }
}

void main() {
  group('SchedulerEngine', () {
    late SchedulerEngine scheduler;
    late MockScheduledJob mockJob;
    late ScheduledTask task1;
    late ScheduledTask task2;

    setUp(() {
      scheduler = SchedulerEngine();
      mockJob = MockScheduledJob();

      task1 = ScheduledTask(
        name: 'task1',
        interval: const Duration(seconds: 30),
        job: mockJob,
      );

      task2 = ScheduledTask(
        name: 'task2',
        interval: const Duration(seconds: 60),
        job: mockJob,
      );
    });

    tearDown(() {
      scheduler.stopAll();
    });

    test('should add task successfully', () {
      scheduler.add(task1);

      expect(scheduler.hasTask('task1'), isTrue);
      expect(scheduler.taskCount, equals(1));
      expect(scheduler.getTaskNames(), contains('task1'));
    });

    test('should throw error when adding duplicate task', () {
      scheduler.add(task1);

      expect(() => scheduler.add(task1), throwsException);
    });

    test('should stop specific task', () {
      scheduler.add(task1);
      scheduler.add(task2);

      scheduler.stop('task1');

      expect(scheduler.isRunning('task1'), isFalse);
      expect(scheduler.isRunning('task2'), isTrue);
      expect(scheduler.activeTasks(), contains('task2'));
      expect(scheduler.activeTasks(), isNot(contains('task1')));
    });

    test('should stop all tasks', () {
      scheduler.add(task1);
      scheduler.add(task2);

      scheduler.stopAll();

      expect(scheduler.activeTasks(), isEmpty);
      expect(scheduler.taskCount, equals(2)); // Tasks still exist but are stopped
    });

    test('should return correct running status', () {
      scheduler.add(task1);

      // Initially should be idle/running depending on timing
      expect(scheduler.isRunning('task1'), isNotNull);

      scheduler.stop('task1');
      expect(scheduler.isRunning('task1'), isFalse);
    });

    test('should return active tasks', () {
      scheduler.add(task1);
      scheduler.add(task2);

      final activeTasks = scheduler.activeTasks();
      expect(activeTasks.length, equals(2));
      expect(activeTasks, contains('task1'));
      expect(activeTasks, contains('task2'));
    });

    test('should pause and resume task', () {
      scheduler.add(task1);

      scheduler.pause('task1');
      expect(scheduler.getTask('task1')?.stats.status, equals(TaskStatus.paused));

      scheduler.resume('task1');
      expect(scheduler.getTask('task1')?.stats.status, equals(TaskStatus.idle));
    });

    test('should return task statistics', () {
      scheduler.add(task1);
      scheduler.add(task2);

      final stats = scheduler.getStats();

      expect(stats.length, equals(2));
      expect(stats.containsKey('task1'), isTrue);
      expect(stats.containsKey('task2'), isTrue);
      expect(stats['task1']?.name, equals('task1'));
      expect(stats['task2']?.name, equals('task2'));
    });

    test('should handle non-existent task operations gracefully', () {
      // These should not throw errors
      scheduler.stop('nonexistent');
      scheduler.pause('nonexistent');
      scheduler.resume('nonexistent');

      expect(scheduler.isRunning('nonexistent'), isFalse);
      expect(scheduler.hasTask('nonexistent'), isFalse);
    });

    test('should remove task', () {
      scheduler.add(task1);
      expect(scheduler.hasTask('task1'), isTrue);

      scheduler.remove('task1');
      expect(scheduler.hasTask('task1'), isFalse);
      expect(scheduler.taskCount, equals(0));
    });

    test('should clear all tasks', () {
      scheduler.add(task1);
      scheduler.add(task2);
      expect(scheduler.taskCount, equals(2));

      scheduler.clear();
      expect(scheduler.taskCount, equals(0));
      expect(scheduler.getTaskNames(), isEmpty);
    });

    test('should get task by name', () {
      scheduler.add(task1);

      final retrievedTask = scheduler.getTask('task1');
      expect(retrievedTask, isNotNull);
      expect(retrievedTask?.name, equals('task1'));

      final nonExistentTask = scheduler.getTask('nonexistent');
      expect(nonExistentTask, isNull);
    });

    test('should return correct task names', () {
      scheduler.add(task1);
      scheduler.add(task2);

      final names = scheduler.getTaskNames();
      expect(names.length, equals(2));
      expect(names, contains('task1'));
      expect(names, contains('task2'));
    });

    test('should handle empty scheduler', () {
      expect(scheduler.taskCount, equals(0));
      expect(scheduler.getTaskNames(), isEmpty);
      expect(scheduler.activeTasks(), isEmpty);
      expect(scheduler.getStats(), isEmpty);

      // Should not throw errors
      scheduler.stopAll();
      scheduler.stop('any');
      scheduler.pause('any');
      scheduler.resume('any');
    });
  });
}
