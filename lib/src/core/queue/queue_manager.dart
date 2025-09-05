import '../../contracts/config/config_contract.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import '../../contracts/queue/queue_monitor.dart';
import 'queue_driver_registry.dart';
import 'queue_factory.dart';
import 'queue_monitor.dart';
import 'queue_worker.dart';

/// Simplified queue manager that handles job dispatch and processing
/// without requiring job registration.
class QueueManager {
  QueueDriver? _defaultDriver;
  String? _defaultDriverName;
  final ConfigInterface _config;
  final QueueMonitor _monitor;

  QueueManager(
    this._config, {
    QueueMonitor? monitor,
    QueueDriver? driver,
    String? driverName,
  }) : _monitor = monitor ?? BasicQueueMonitor() {
    if (driver != null) {
      _defaultDriver = driver;
      _defaultDriverName = driverName ?? 'mock';
    }
  }

  /// Gets the default queue driver.
  QueueDriver get driver => _defaultDriver!;

  /// Gets the name of the default driver.
  String get defaultDriverName => _defaultDriverName!;

  /// Gets the queue monitor for metrics.
  QueueMonitor get monitor => _monitor;

  /// Initializes the queue manager and resolves the driver.
  Future<void> init() async {
    // Only resolve driver if not already set (for testing)
    if (_defaultDriverName == null) {
      final (defaultDriver, defaultDriverName) = QueueFactory.resolve(_config);
      _defaultDriver = defaultDriver;
      _defaultDriverName = defaultDriverName;
    }
  }

  /// Dispatches a job to the queue with optional delay.
  /// This is the main method - just dispatch any job without registration!
  Future<void> dispatch(QueueJob job, {Duration? delay}) async {
    _monitor.jobQueued(job);

    try {
      await _defaultDriver!.push(job, delay: delay);
    } catch (e) {
      _monitor.jobFailed(job, e, Duration.zero);
      rethrow;
    }
  }

  /// Convenient method to dispatch multiple jobs at once.
  Future<void> dispatchBatch(List<QueueJob> jobs, {Duration? delay}) async {
    for (final job in jobs) {
      await dispatch(job, delay: delay);
    }
  }

  /// Processes jobs from the queue.
  Future<void> process() async {
    try {
      await _defaultDriver!.process();
    } catch (e) {
      // Log error but don't rethrow to keep worker running
      print('Queue processing error: $e');
    }
  }

  /// Starts a queue worker with the specified configuration.
  Future<void> startWorker({
    int? maxJobs,
    Duration delay = const Duration(seconds: 1),
    Duration? timeout,
    bool runInBackground = false,
    void Function(dynamic error, StackTrace stack)? onError,
    void Function(QueueJob job)? onJobStart,
    void Function(QueueJob job, dynamic result)? onJobComplete,
    void Function(QueueJob job, dynamic error, StackTrace stack)? onJobError,
  }) async {
    final config = QueueWorkerConfig(
      maxJobs: maxJobs,
      delay: delay,
      timeout: timeout,
      runInBackground: runInBackground,
      onError: onError,
      onJobStart: onJobStart,
      onJobComplete: onJobComplete,
      onJobError: onJobError,
    );

    final worker = QueueWorker(_defaultDriver!, config);
    await worker.start();
  }

  /// Gets current queue metrics.
  Map<String, dynamic> getMetrics() {
    return _monitor.getMetrics().toJson();
  }

  /// Resets queue metrics.
  void resetMetrics() {
    _monitor.reset();
  }

  /// Gets the driver registry for driver management.
  static QueueDriverRegistry get registry => QueueFactory.instance.registry;
}
