import 'package:test/test.dart';

import '../../../lib/src/contracts/scheduler/job_definition.dart';
import '../../../lib/src/contracts/scheduler/scheduled_job.dart';
import '../../../lib/src/contracts/scheduler/task_stats.dart';
import '../../../lib/src/core/scheduler/core/job_registry.dart';
import '../../../lib/src/core/scheduler/core/scheduled_task.dart';
import '../../../lib/src/core/scheduler/scheduler_bootstrap.dart';

// Mock job for testing
class IntegrationTestJob implements ScheduledJob {
  @override
  final String name;

  bool executed = false;

  IntegrationTestJob(this.name);

  @override
  Future<void> execute() async {
    executed = true;
  }
}

void main() {
  group('Scheduler Integration Tests', () {
    setUp(() {
      // Clear everything before each test
      SchedulerJobRegistry.clear();
      scheduler.clear();
    });

    tearDown(() {
      // Clean up after each test
      scheduler.stopAll();
      SchedulerJobRegistry.clear();
    });

    test('should bootstrap scheduler with custom tasks', () {
      final customJob = JobDefinition(
        name: 'custom_job',
        factory: (config) => IntegrationTestJob('custom_job'),
      );

      final task = ScheduledTask(
        name: 'integration_task',
        interval: const Duration(seconds: 30),
        job: IntegrationTestJob('test_job'),
      );

      startSchedulers(
        tasks: [task],
        configJobs: [customJob],
      );

      expect(scheduler.hasTask('integration_task'), isTrue);
      expect(SchedulerJobRegistry.isRegistered('custom_job'), isTrue);
      expect(SchedulerJobRegistry.isRegistered('ping'), isTrue); // Built-in
    });

    test('should handle empty bootstrap', () {
      startSchedulers();

      expect(scheduler.taskCount, equals(0));
      expect(SchedulerJobRegistry.count, greaterThan(0)); // Built-ins registered
    });

    test('should execute tasks through scheduler', () async {
      final testJob = IntegrationTestJob('execution_test');
      final task = ScheduledTask(
        name: 'execution_task',
        interval: const Duration(seconds: 1), // Short interval for testing
        job: testJob,
        runOnce: true, // Only run once for predictable testing
      );

      scheduler.add(task);

      // Wait for task to execute
      await Future.delayed(const Duration(milliseconds: 100));

      // Task should have been executed
      expect(testJob.executed, isTrue);
    });

    test('should handle multiple tasks with different intervals', () async {
      final job1 = IntegrationTestJob('job1');
      final job2 = IntegrationTestJob('job2');

      final task1 = ScheduledTask(
        name: 'task1',
        interval: const Duration(milliseconds: 50),
        job: job1,
        runOnce: true,
      );

      final task2 = ScheduledTask(
        name: 'task2',
        interval: const Duration(milliseconds: 100),
        job: job2,
        runOnce: true,
      );

      scheduler.add(task1);
      scheduler.add(task2);

      // Wait for both tasks to execute
      await Future.delayed(const Duration(milliseconds: 150));

      expect(job1.executed, isTrue);
      expect(job2.executed, isTrue);
    });

    test('should provide task statistics', () async {
      final testJob = IntegrationTestJob('stats_job');
      final task = ScheduledTask(
        name: 'stats_task',
        interval: const Duration(milliseconds: 50),
        job: testJob,
        runOnce: true,
      );

      scheduler.add(task);

      // Wait for task to complete
      await Future.delayed(const Duration(milliseconds: 100));

      final stats = scheduler.getStats();
      expect(stats.containsKey('stats_task'), isTrue);

      final taskStats = stats['stats_task']!;
      expect(taskStats.name, equals('stats_task'));
      expect(taskStats.successCount, equals(1));
      expect(taskStats.failureCount, equals(0));
    });

    test('should handle task lifecycle operations', () {
      final task = ScheduledTask(
        name: 'lifecycle_task',
        interval: const Duration(seconds: 30),
        job: IntegrationTestJob('lifecycle_job'),
      );

      scheduler.add(task);

      // Test pause/resume
      scheduler.pause('lifecycle_task');
      expect(scheduler.getTask('lifecycle_task')?.stats.status, equals(TaskStatus.paused));

      scheduler.resume('lifecycle_task');
      expect(scheduler.getTask('lifecycle_task')?.stats.status, equals(TaskStatus.idle));

      // Test stop
      scheduler.stop('lifecycle_task');
      expect(scheduler.isRunning('lifecycle_task'), isFalse);
    });

    test('should manage active tasks list', () {
      final task1 = ScheduledTask(
        name: 'active_task1',
        interval: const Duration(seconds: 30),
        job: IntegrationTestJob('active_job1'),
      );

      final task2 = ScheduledTask(
        name: 'active_task2',
        interval: const Duration(seconds: 30),
        job: IntegrationTestJob('active_job2'),
      );

      scheduler.add(task1);
      scheduler.add(task2);

      var activeTasks = scheduler.activeTasks();
      expect(activeTasks.length, equals(2));
      expect(activeTasks, contains('active_task1'));
      expect(activeTasks, contains('active_task2'));

      scheduler.stop('active_task1');
      activeTasks = scheduler.activeTasks();
      expect(activeTasks.length, equals(1));
      expect(activeTasks, contains('active_task2'));
      expect(activeTasks, isNot(contains('active_task1')));
    });

    test('should handle task removal', () {
      final task = ScheduledTask(
        name: 'removal_task',
        interval: const Duration(seconds: 30),
        job: IntegrationTestJob('removal_job'),
      );

      scheduler.add(task);
      expect(scheduler.hasTask('removal_task'), isTrue);

      scheduler.remove('removal_task');
      expect(scheduler.hasTask('removal_task'), isFalse);
      expect(scheduler.taskCount, equals(0));
    });

    test('should handle concurrent task execution', () async {
      final jobs = List.generate(5, (i) => IntegrationTestJob('concurrent_job_$i'));
      final tasks = jobs.map((job) => ScheduledTask(
        name: 'concurrent_task_${jobs.indexOf(job)}',
        interval: const Duration(milliseconds: 10),
        job: job,
        runOnce: true,
      ),).toList();

      for (final task in tasks) {
        scheduler.add(task);
      }

      // Wait for all tasks to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // All jobs should have executed
      for (final job in jobs) {
        expect(job.executed, isTrue);
      }
    });
  });
}
