import 'dart:async';

import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import 'dlq/index.dart';

/// Configuration for enhanced queue worker behavior.
class QueueWorkerConfig {
  final int? maxJobs;
  final Duration delay;
  final Duration? timeout;
  final bool runInBackground;
  final int concurrency;
  final Duration gracefulShutdownTimeout;
  final void Function(dynamic error, StackTrace stack)? onError;
  final void Function(QueueJob job)? onJobStart;
  final void Function(QueueJob job, dynamic result)? onJobComplete;
  final void Function(QueueJob job, dynamic error, StackTrace stack)?
      onJobError;
  final void Function()? onShutdown;
  final FailedJobHandler? failedJobHandler;

  const QueueWorkerConfig({
    this.maxJobs,
    this.delay = const Duration(seconds: 1),
    this.timeout,
    this.runInBackground = false,
    this.concurrency = 1,
    this.gracefulShutdownTimeout = const Duration(seconds: 30),
    this.onError,
    this.onJobStart,
    this.onJobComplete,
    this.onJobError,
    this.onShutdown,
    this.failedJobHandler,
  });
}

/// Enhanced queue worker with timeout enforcement and graceful shutdown
class QueueWorker {
  final QueueDriver _driver;
  final QueueWorkerConfig _config;
  bool _shouldStop = false;
  final Set<Future<void>> _runningJobs = {};
  final _shutdownCompleter = Completer<void>();
  Timer? _workerTimer;

  QueueWorker(this._driver, this._config);

  /// Starts the worker process
  Future<void> start() async {
    int processed = 0;
    final start = DateTime.now();

    Future<void> workerLogic() async {
      while (!_shouldStop) {
        try {
          // Check if we can process more jobs (concurrency limit)
          if (_runningJobs.length < _config.concurrency) {
            final jobFuture = _processNextJobWithTimeout();
            _runningJobs.add(jobFuture);

            // Remove from running set when complete
            jobFuture.whenComplete(() => _runningJobs.remove(jobFuture));

            processed++;

            // Check termination conditions
            if (_shouldTerminate(processed, start)) {
              await _gracefulShutdown();
              break;
            }
          }

          await Future.delayed(_config.delay);
        } catch (e, stack) {
          _config.onError?.call(e, stack);
        }
      }

      _shutdownCompleter.complete();
    }

    if (_config.runInBackground) {
      Future(workerLogic);
    } else {
      await workerLogic();
    }
  }

  /// Processes the next job with timeout enforcement
  Future<void> _processNextJobWithTimeout() async {
    try {
      // Create a processing function
      Future<void> processJob() async {
        // This is a simplified approach - in reality, we'd need to capture
        // the job from the driver's process method
        await _driver.process();
      }

      // Apply timeout if configured
      if (_config.timeout != null) {
        await processJob().timeout(
          _config.timeout!,
          onTimeout: () {
            final error = TimeoutException(
              'Job execution exceeded timeout of ${_config.timeout}',
            );
            _config.onError?.call(error, StackTrace.current);
            throw error;
          },
        );
      } else {
        await processJob();
      }
    } catch (e, stack) {
      _config.onError?.call(e, stack);
    }
  }

  /// Determines if the worker should stop based on configuration
  bool _shouldTerminate(int processed, DateTime start) {
    if (_config.maxJobs != null && processed >= _config.maxJobs!) {
      return true;
    }

    if (_config.timeout != null &&
        DateTime.now().difference(start) >= _config.timeout!) {
      return true;
    }

    return false;
  }

  /// Gracefully shutdown the worker
  Future<void> _gracefulShutdown() async {
    print('🛑 Initiating graceful shutdown...');
    _shouldStop = true;

    // Wait for running jobs to complete or timeout
    try {
      await Future.wait(_runningJobs).timeout(
        _config.gracefulShutdownTimeout,
        onTimeout: () {
          print('⚠️ Graceful shutdown timeout reached, forcing shutdown');
          return <void>[];
        },
      );
      print('✅ All jobs completed gracefully');
    } catch (e) {
      print('⚠️ Error during graceful shutdown: $e');
    }

    _config.onShutdown?.call();
    _workerTimer?.cancel();
  }

  /// Stop the worker (for background workers)
  Future<void> stop({bool graceful = true}) async {
    if (graceful) {
      await _gracefulShutdown();
      await _shutdownCompleter.future;
    } else {
      _shouldStop = true;
      _workerTimer?.cancel();
      _shutdownCompleter.complete();
    }
  }

  /// Check if worker is running
  bool get isRunning => !_shouldStop;

  /// Get count of currently running jobs
  int get runningJobCount => _runningJobs.length;
}

/// Worker pool for concurrent job processing
class QueueWorkerPool {
  final QueueDriver _driver;
  final int _workerCount;
  final QueueWorkerConfig _config;
  final List<QueueWorker> _workers = [];
  bool _isRunning = false;

  QueueWorkerPool({
    required QueueDriver driver,
    int workerCount = 4,
    QueueWorkerConfig? config,
  })  : _driver = driver,
        _workerCount = workerCount,
        _config = config ?? const QueueWorkerConfig();

  /// Start the worker pool
  Future<void> start() async {
    if (_isRunning) {
      throw StateError('Worker pool is already running');
    }

    _isRunning = true;

    // Create and start workers
    for (int i = 0; i < _workerCount; i++) {
      final worker = QueueWorker(_driver, _config);
      _workers.add(worker);

      // Start in background
      worker.start();
    }

    print('✅ Started worker pool with $_workerCount workers');
  }

  /// Stop the worker pool
  Future<void> stop({bool graceful = true}) async {
    if (!_isRunning) {
      return;
    }

    print('🛑 Stopping worker pool...');

    // Stop all workers
    await Future.wait(
      _workers.map((worker) => worker.stop(graceful: graceful)),
    );

    _workers.clear();
    _isRunning = false;

    print('✅ Worker pool stopped');
  }

  /// Get pool statistics
  Map<String, dynamic> getStats() {
    return {
      'workerCount': _workerCount,
      'isRunning': _isRunning,
      'activeWorkers': _workers.where((w) => w.isRunning).length,
      'totalRunningJobs': _workers.fold(0, (sum, w) => sum + w.runningJobCount),
    };
  }

  /// Scale the worker pool (add or remove workers)
  Future<void> scale(int newWorkerCount) async {
    if (newWorkerCount < 1) {
      throw ArgumentError('Worker count must be at least 1');
    }

    if (newWorkerCount == _workerCount) {
      return;
    }

    if (newWorkerCount > _workerCount) {
      // Add workers
      final workersToAdd = newWorkerCount - _workerCount;
      for (int i = 0; i < workersToAdd; i++) {
        final worker = QueueWorker(_driver, _config);
        _workers.add(worker);
        if (_isRunning) {
          worker.start();
        }
      }
      print('✅ Scaled up to $newWorkerCount workers');
    } else {
      // Remove workers
      final workersToRemove = _workerCount - newWorkerCount;
      for (int i = 0; i < workersToRemove; i++) {
        final worker = _workers.removeLast();
        await worker.stop();
      }
      print('✅ Scaled down to $newWorkerCount workers');
    }
  }

  /// Check if pool is running
  bool get isRunning => _isRunning;

  /// Get worker count
  int get workerCount => _workers.length;
}

/// Statistics and monitoring for enhanced queue operations
class QueueWorkerPoolStats {
  int jobsProcessed = 0;
  int jobsFailed = 0;
  int jobsRetried = 0;
  int jobsTimedOut = 0;
  DateTime? startTime;
  DateTime? lastActivity;
  final List<Duration> _processingTimes = [];
  final int _maxSamples = 1000;

  void recordJobProcessed(Duration processingTime) {
    jobsProcessed++;
    lastActivity = DateTime.now();
    _recordProcessingTime(processingTime);
  }

  void recordJobFailed() {
    jobsFailed++;
    lastActivity = DateTime.now();
  }

  void recordJobRetried() {
    jobsRetried++;
    lastActivity = DateTime.now();
  }

  void recordJobTimedOut() {
    jobsTimedOut++;
    lastActivity = DateTime.now();
  }

  void _recordProcessingTime(Duration duration) {
    _processingTimes.add(duration);
    if (_processingTimes.length > _maxSamples) {
      _processingTimes.removeAt(0);
    }
  }

  Duration get uptime {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }

  double get failureRate {
    if (jobsProcessed == 0) return 0.0;
    return jobsFailed / jobsProcessed;
  }

  double get timeoutRate {
    if (jobsProcessed == 0) return 0.0;
    return jobsTimedOut / jobsProcessed;
  }

  Duration get averageProcessingTime {
    if (_processingTimes.isEmpty) return Duration.zero;
    final totalMs = _processingTimes.fold<int>(
      0,
      (sum, d) => sum + d.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _processingTimes.length);
  }

  Duration get p50ProcessingTime => _percentile(0.5);
  Duration get p95ProcessingTime => _percentile(0.95);
  Duration get p99ProcessingTime => _percentile(0.99);

  Duration _percentile(double percentile) {
    if (_processingTimes.isEmpty) return Duration.zero;
    final sorted = List<Duration>.from(_processingTimes)
      ..sort((a, b) => a.inMilliseconds.compareTo(b.inMilliseconds));
    final index = (sorted.length * percentile).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  double get throughput {
    if (startTime == null) return 0.0;
    final uptimeSeconds = uptime.inSeconds;
    if (uptimeSeconds == 0) return 0.0;
    return jobsProcessed / uptimeSeconds;
  }

  Map<String, dynamic> toJson() {
    return {
      'jobs_processed': jobsProcessed,
      'jobs_failed': jobsFailed,
      'jobs_retried': jobsRetried,
      'jobs_timed_out': jobsTimedOut,
      'uptime_seconds': uptime.inSeconds,
      'failure_rate': failureRate,
      'timeout_rate': timeoutRate,
      'throughput_per_second': throughput,
      'average_processing_time_ms': averageProcessingTime.inMilliseconds,
      'p50_processing_time_ms': p50ProcessingTime.inMilliseconds,
      'p95_processing_time_ms': p95ProcessingTime.inMilliseconds,
      'p99_processing_time_ms': p99ProcessingTime.inMilliseconds,
      'start_time': startTime?.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
    };
  }
}
