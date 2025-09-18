import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';

/// Configuration for queue worker behavior.
class QueueWorkerConfig {
  final int? maxJobs;
  final Duration delay;
  final Duration? timeout;
  final bool runInBackground;
  final void Function(dynamic error, StackTrace stack)? onError;
  final void Function(QueueJob job)? onJobStart;
  final void Function(QueueJob job, dynamic result)? onJobComplete;
  final void Function(QueueJob job, dynamic error, StackTrace stack)? onJobError;

  const QueueWorkerConfig({
    this.maxJobs,
    this.delay = const Duration(seconds: 1),
    this.timeout,
    this.runInBackground = false,
    this.onError,
    this.onJobStart,
    this.onJobComplete,
    this.onJobError,
  });
}

/// Handles the execution of queued jobs with proper error handling and monitoring.
class QueueWorker {
  final QueueDriver _driver;
  final QueueWorkerConfig _config;

  QueueWorker(this._driver, this._config);

  /// Starts the worker process.
  Future<void> start() async {
    int processed = 0;
    final start = DateTime.now();
    bool running = true;

    Future<void> workerLogic() async {
      while (running) {
        try {
          await _processNextJob();

          processed++;

          // Check termination conditions
          if (_shouldStop(processed, start)) {
            running = false;
            break;
          }

          await Future.delayed(_config.delay);
        } catch (e, stack) {
          _config.onError?.call(e, stack);
        }
      }
    }

    if (_config.runInBackground) {
      Future(workerLogic);
    } else {
      await workerLogic();
    }
  }

  /// Processes the next available job.
  Future<void> _processNextJob() async {
    try {
      await _driver.process();
    } catch (e, stack) {
      _config.onError?.call(e, stack);
    }
  }

  /// Determines if the worker should stop based on configuration.
  bool _shouldStop(int processed, DateTime start) {
    if (_config.maxJobs != null && processed >= _config.maxJobs!) {
      return true;
    }

    if (_config.timeout != null &&
        DateTime.now().difference(start) >= _config.timeout!) {
      return true;
    }

    return false;
  }

  /// Stops the worker (for background workers).
  void stop() {
    // Implementation would depend on the specific driver
    // For now, this is a placeholder for future enhancement
  }
}

/// Statistics and monitoring for queue operations.
class QueueStats {
  int jobsProcessed = 0;
  int jobsFailed = 0;
  int jobsRetried = 0;
  DateTime? startTime;
  DateTime? lastActivity;

  void recordJobProcessed() {
    jobsProcessed++;
    lastActivity = DateTime.now();
  }

  void recordJobFailed() {
    jobsFailed++;
    lastActivity = DateTime.now();
  }

  void recordJobRetried() {
    jobsRetried++;
    lastActivity = DateTime.now();
  }

  Duration get uptime {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }

  double get failureRate {
    if (jobsProcessed == 0) return 0.0;
    return jobsFailed / jobsProcessed;
  }

  Map<String, dynamic> toJson() {
    return {
      'jobs_processed': jobsProcessed,
      'jobs_failed': jobsFailed,
      'jobs_retried': jobsRetried,
      'uptime_seconds': uptime.inSeconds,
      'failure_rate': failureRate,
      'start_time': startTime?.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
    };
  }
}
