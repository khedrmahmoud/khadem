import 'dart:async';

import '../../contracts/scheduler/scheduler_engine_contract.dart';
import '../../contracts/scheduler/task_stats.dart';
import 'core/scheduled_task.dart';

/// The main scheduler engine that manages scheduled tasks
class SchedulerEngine implements SchedulerEngineContract {
  final Map<String, ScheduledTask> _tasks = {};

  @override
  void add(ScheduledTask task) {
    if (_tasks.containsKey(task.name)) {
      throw Exception('Task "${task.name}" already exists.');
    }

    _tasks[task.name] = task;

    void scheduleNext(Duration delay) {
      task.timer = Timer(delay, () => task.run(scheduleNext));
    }

    task.start(scheduleNext);
  }

  @override
  void stop(String name) => _tasks[name]?.stop();

  @override
  void stopAll() {
    for (final task in _tasks.values) {
      task.stop();
    }
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
    _tasks[name]?.pause();
  }

  @override
  void resume(String name) {
    final task = _tasks[name];
    if (task == null) return;

    void scheduleNext(Duration delay) {
      task.timer = Timer(delay, () => task.run(scheduleNext));
    }

    task.resume(scheduleNext);
  }

  @override
  Map<String, TaskStats> getStats() {
    return Map.fromEntries(
      _tasks.entries.map((e) => MapEntry(e.key, e.value.stats)),
    );
  }
}
