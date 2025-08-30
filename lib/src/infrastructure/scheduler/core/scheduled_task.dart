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
  
  bool _isRunning = false;
  bool _isPaused = false;
  int _successCount = 0;
  int _failureCount = 0;
  DateTime? _lastRun;
  DateTime? _nextRun;
  Duration _totalExecutionTime = Duration.zero;
  int _retryCount = 0;

  /// Creates a new scheduled task
  ScheduledTask({
    required this.name,
    required this.interval,
    required this.job,
    this.timeZone = 'UTC',
    this.retryOnFail = false,
    this.runOnce = false,
    this.maxRetries = 3,
  });

  /// Creates a scheduled task from a configuration map
  factory ScheduledTask.fromConfig(Map<String, dynamic> config) {
    final jobName = config['job'] as String;
    final job = SchedulerJobRegistry.resolve(jobName, config);

    if (job == null) {
      throw Exception('Job "$jobName" not found in TaskRunner.');
    }

    if (config['cron'] != null) {
      Khadem.logger.warning(
          '⚠️ Cron expressions are not supported. Task "${config['name']}" will be ignored.',);
      throw ArgumentError('Cron is not supported in this version.');
    }

    if (config['interval'] == null) {
      throw ArgumentError(
          'Missing "interval" for scheduled task "${config['name']}"',);
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
  TaskStats get stats => TaskStats(
        name: name,
        lastRun: _lastRun,
        nextRun: _nextRun,
        successCount: _successCount,
        failureCount: _failureCount,
        averageExecutionTime: _totalExecutionTime.inMilliseconds /
            (_successCount + _failureCount).clamp(1, double.infinity),
        status: _getStatus(),
      );

  TaskStatus _getStatus() {
    if (_isRunning) return TaskStatus.running;
    if (_isPaused) return TaskStatus.paused;
    if (timer == null) return TaskStatus.stopped;
    if (_failureCount > 0 && !retryOnFail) return TaskStatus.failed;
    return TaskStatus.idle;
  }

  /// Starts the task
  void start(Function(Duration) scheduleNext) {
    if (_isPaused) return;
    _scheduleNext(scheduleNext);
  }

  /// Pauses the task
  void pause() {
    _isPaused = true;
    timer?.cancel();
  }

  /// Resumes a paused task
  void resume(Function(Duration) scheduleNext) {
    _isPaused = false;
    _scheduleNext(scheduleNext);
  }

  void _scheduleNext(Function(Duration) scheduleNext) {
    final delay = _nextDelay();
    _nextRun = DateTime.now().add(delay);
    scheduleNext(delay);
  }

  Duration _nextDelay() {
    return interval;
  }

  /// Runs the task
  Future<void> run(Function(Duration) scheduleNext) async {
    if (_isRunning || _isPaused) return;
    _isRunning = true;
    _lastRun = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      await job.execute();
      _successCount++;
      _retryCount = 0;
    } catch (e, s) {
      _failureCount++;
      Khadem.logger.error('❌ Error in [$name]: $e\n$s');
      
      if (retryOnFail && _retryCount < maxRetries) {
        _retryCount++;
        Future.delayed(
          Duration(seconds: 5 * _retryCount), // Exponential backoff
          () => run(scheduleNext),
        );
        return;
      }
    } finally {
      stopwatch.stop();
      _totalExecutionTime += stopwatch.elapsed;
      _isRunning = false;
    }

    if (!runOnce && !_isPaused) {
      _scheduleNext(scheduleNext);
    }
  }

  /// Stops the task
  void stop() {
    timer?.cancel();
    timer = null;
    _isPaused = false;
  }
}
