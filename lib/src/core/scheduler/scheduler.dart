import 'dart:async';

import '../../application/khadem.dart';
import '../../contracts/scheduler/scheduler_engine_contract.dart';
import '../../contracts/scheduler/task_stats.dart';
import 'core/scheduled_task.dart';

/// The main scheduler engine that manages scheduled tasks
///
/// This class is responsible for:
/// - Adding and managing scheduled tasks
/// - Starting, stopping, pausing, and resuming tasks
/// - Providing statistics about task execution
/// - Ensuring thread-safe operations on tasks
class SchedulerEngine implements SchedulerEngineContract {
  /// Internal storage for all registered tasks
  final Map<String, ScheduledTask> _tasks = {};

  /// Logger instance for this scheduler
  final _logger = Khadem.logger;

  @override
  void add(ScheduledTask task) {
    if (_tasks.containsKey(task.name)) {
      throw Exception('Task "${task.name}" already exists.');
    }

    _tasks[task.name] = task;
    _logger.info('✅ Task "${task.name}" added to scheduler');

    void scheduleNext(Duration delay) {
      task.timer = Timer(delay, () => task.run(scheduleNext));
    }

    task.start(scheduleNext);
  }

  @override
  void stop(String name) {
    final task = _tasks[name];
    if (task == null) {
      _logger.warning('⚠️ Task "$name" not found');
      return;
    }

    task.stop();
    _logger.info('🛑 Task "$name" stopped');
  }

  @override
  void stopAll() {
    if (_tasks.isEmpty) {
      _logger.info('ℹ️ No tasks to stop');
      return;
    }

    for (final task in _tasks.values) {
      task.stop();
    }
    _logger.info('🛑 All tasks stopped (${_tasks.length} tasks)');
  }

  @override
  bool isRunning(String name) {
    final task = _tasks[name];
    return task?.stats.status == TaskStatus.running;
  }

  @override
  List<String> activeTasks() => _tasks.keys
      .where((name) => _tasks[name]?.stats.status != TaskStatus.stopped)
      .toList();

  @override
  void pause(String name) {
    final task = _tasks[name];
    if (task == null) {
      _logger.warning('⚠️ Task "$name" not found');
      return;
    }

    task.pause();
    _logger.info('⏸️ Task "$name" paused');
  }

  @override
  void resume(String name) {
    final task = _tasks[name];
    if (task == null) {
      _logger.warning('⚠️ Task "$name" not found');
      return;
    }

    void scheduleNext(Duration delay) {
      task.timer = Timer(delay, () => task.run(scheduleNext));
    }

    task.resume(scheduleNext);
    _logger.info('▶️ Task "$name" resumed');
  }

  @override
  Map<String, TaskStats> getStats() {
    return Map.fromEntries(
      _tasks.entries.map((e) => MapEntry(e.key, e.value.stats)),
    );
  }

  /// Get a specific task by name
  ScheduledTask? getTask(String name) => _tasks[name];

  /// Get all registered task names
  List<String> getTaskNames() => _tasks.keys.toList();

  /// Check if a task exists
  bool hasTask(String name) => _tasks.containsKey(name);

  /// Get the count of registered tasks
  int get taskCount => _tasks.length;

  /// Remove a task from the scheduler
  void remove(String name) {
    final task = _tasks.remove(name);
    if (task != null) {
      task.stop();
      _logger.info('🗑️ Task "$name" removed from scheduler');
    } else {
      _logger.warning('⚠️ Task "$name" not found for removal');
    }
  }

  /// Clear all tasks from the scheduler
  void clear() {
    stopAll();
    _tasks.clear();
    _logger.info('🧹 Scheduler cleared');
  }
}
