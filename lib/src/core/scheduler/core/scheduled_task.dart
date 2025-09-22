import 'dart:async';

import '../../../application/khadem.dart';
import '../../../contracts/scheduler/scheduled_job.dart';
import '../../../contracts/scheduler/task_stats.dart';
import 'job_registry.dart';

/// A scheduled task that can be executed at specified intervals
class ScheduledTask {
  /// The name of the task
  final String name;

  /// The interval at which the task should run
  final Duration interval;

  /// The job to execute
  final ScheduledJob job;

  /// The timezone in which the task should run
  final String timeZone;

  /// Whether to retry the task on failure
  final bool retryOnFail;

  /// Whether the task should only run once
  final bool runOnce;

  /// The maximum number of retries on failure
  final int maxRetries;

  /// The timer that schedules the task
  Timer? timer;

  /// Internal task state manager
  final _TaskState _state;

  /// Creates a new scheduled task
  ScheduledTask({
    required this.name,
    required this.interval,
    required this.job,
    this.timeZone = 'UTC',
    this.retryOnFail = false,
    this.runOnce = false,
    this.maxRetries = 3,
  }) : _state = _TaskState();

  /// Creates a scheduled task from a configuration map
  factory ScheduledTask.fromConfig(Map<String, dynamic> config) {
    final jobName = config['job'] as String;
    final job = SchedulerJobRegistry.resolve(jobName, config);

    if (job == null) {
      throw Exception('Job "$jobName" not found in TaskRunner.');
    }

    if (config['cron'] != null) {
      Khadem.logger.warning(
        '⚠️ Cron expressions are not supported. Task "${config['name']}" will be ignored.',
      );
      throw ArgumentError('Cron is not supported in this version.');
    }

    if (config['interval'] == null) {
      throw ArgumentError(
        'Missing "interval" for scheduled task "${config['name']}"',
      );
    }

    return ScheduledTask(
      name: config['name'] as String,
      interval: Duration(seconds: config['interval'] as int),
      timeZone: config['timezone']?.toString() ?? 'UTC',
      job: job,
      retryOnFail: config['retryOnFail'] as bool? ?? false,
      runOnce: config['runOnce'] as bool? ?? false,
      maxRetries: config['maxRetries'] as int? ?? 3,
    );
  }

  /// Get the current statistics for this task
  TaskStats get stats => _state.getStats(name);

  /// Starts the task
  void start(Function(Duration) scheduleNext) {
    if (_state.isPaused) return;
    _scheduleNext(scheduleNext);
  }

  /// Pauses the task
  void pause() {
    _state.pause();
    timer?.cancel();
  }

  /// Resumes a paused task
  void resume(Function(Duration) scheduleNext) {
    _state.resume();
    _scheduleNext(scheduleNext);
  }

  /// Runs the task
  Future<void> run(Function(Duration) scheduleNext) async {
    if (_state.isRunning || _state.isPaused) return;

    _state.markRunning();
    final stopwatch = Stopwatch()..start();

    try {
      await job.execute();
      _state.recordSuccess();
    } catch (e, s) {
      _state.recordFailure();
      Khadem.logger.error('❌ Error in [$name]: $e\n$s');

      if (retryOnFail && _state.retryCount < maxRetries) {
        _state.incrementRetry();
        Future.delayed(
          Duration(seconds: 5 * _state.retryCount), // Exponential backoff
          () => run(scheduleNext),
        );
        return;
      }
    } finally {
      stopwatch.stop();
      _state.recordExecutionTime(stopwatch.elapsed);
      _state.markIdle();
    }

    if (!runOnce && !_state.isPaused) {
      _scheduleNext(scheduleNext);
    }
  }

  /// Stops the task
  void stop() {
    timer?.cancel();
    timer = null;
    _state.stop();
  }

  void _scheduleNext(Function(Duration) scheduleNext) {
    final delay = _nextDelay();
    _state.setNextRun(DateTime.now().add(delay));
    scheduleNext(delay);
  }

  Duration _nextDelay() {
    return interval;
  }
}

/// Internal class to manage task state and statistics
class _TaskState {
  bool _isRunning = false;
  bool _isPaused = false;
  int _successCount = 0;
  int _failureCount = 0;
  DateTime? _lastRun;
  DateTime? _nextRun;
  Duration _totalExecutionTime = Duration.zero;
  int _retryCount = 0;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get retryCount => _retryCount;

  void pause() => _isPaused = true;
  void resume() => _isPaused = false;
  void stop() => _isPaused = false;

  void markRunning() => _isRunning = true;
  void markIdle() => _isRunning = false;

  void recordSuccess() {
    _successCount++;
    _retryCount = 0;
  }

  void recordFailure() => _failureCount++;

  void incrementRetry() => _retryCount++;

  void recordExecutionTime(Duration time) => _totalExecutionTime += time;

  void setNextRun(DateTime nextRun) => _nextRun = nextRun;

  TaskStats getStats(String name) {
    return TaskStats(
      name: name,
      lastRun: _lastRun,
      nextRun: _nextRun,
      successCount: _successCount,
      failureCount: _failureCount,
      averageExecutionTime: _totalExecutionTime.inMilliseconds /
          (_successCount + _failureCount).clamp(1, double.infinity),
      status: _getStatus(),
    );
  }

  TaskStatus _getStatus() {
    if (_isRunning) return TaskStatus.running;
    if (_isPaused) return TaskStatus.paused;
    if (_failureCount > 0 && _retryCount >= 3) return TaskStatus.failed;
    return TaskStatus.idle;
  }
}
