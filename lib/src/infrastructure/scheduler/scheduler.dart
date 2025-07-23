import 'dart:async';

import 'core/scheduled_task.dart';

class SchedulerEngine {
  final Map<String, ScheduledTask> _tasks = {};

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

  void stop(String name) => _tasks[name]?.stop();

  void stopAll() {
    for (final task in _tasks.values) {
      task.stop();
    }
  }

  bool isRunning(String name) => _tasks[name]?.timer?.isActive ?? false;

  List<String> activeTasks() => _tasks.keys.toList();
}
