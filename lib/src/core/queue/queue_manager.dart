import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_driver_registry.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/contracts/queue/queue_monitor.dart';
import 'package:khadem/src/core/queue/config/queue_config_loader.dart';
import 'package:khadem/src/core/queue/queue_driver_registry.dart';
import 'package:khadem/src/core/queue/queue_monitor.dart';
import 'package:khadem/src/core/queue/queue_worker.dart';
import 'package:khadem/src/support/exceptions/queue_exception.dart';

/// Simplified queue manager that handles job dispatch and processing
/// without requiring job registration.
class QueueManager {
  QueueDriver? _defaultDriver;
  String? _defaultDriverName;
  final ConfigInterface _config;
  final QueueMonitor _monitor;
  final IQueueDriverRegistry _registry;
  final QueueConfigLoader _configLoader;

  QueueManager(
    this._config, {
    QueueMonitor? monitor,
    QueueDriver? driver,
    String? driverName,
    IQueueDriverRegistry? registry,
    QueueConfigLoader? configLoader,
  })  : _monitor = monitor ?? BasicQueueMonitor(),
        _registry = registry ?? QueueDriverRegistry(),
        _configLoader = configLoader ?? QueueConfigLoader() {
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

  /// Gets the driver registry.
  IQueueDriverRegistry get registry => _registry;

  /// Gets the config loader.
  QueueConfigLoader get configLoader => _configLoader;

  /// Loads queue configuration from the application's config.
  ///
  /// This method reads queue settings from the configuration and automatically
  /// registers the appropriate queue drivers based on the configuration.
  ///
  /// The configuration should have the following structure:
  /// ```yaml
  /// queue:
  ///   default: memory
  ///   drivers:
  ///     memory:
  ///       driver: memory
  ///     file:
  ///       driver: file
  ///       path: ./storage/queue
  /// ```
  ///
  /// Throws [QueueException] if the configuration is invalid or if a driver
  /// cannot be initialized.
  void loadFromConfig() {
    _configLoader.loadFromConfig(_config, _registry);
    // Update default driver after config loading
    try {
      _defaultDriver = _registry.getDefaultDriver();
      _defaultDriverName = _registry.getDefaultDriverName();
    } catch (e) {
      // Keep existing driver if config loading fails
    }
  }

  /// Registers a queue driver with the given name.
  ///
  /// The first registered driver automatically becomes the default driver.
  /// Use [setDefaultDriver] to change the default driver later.
  ///
  /// Throws [QueueException] if the driver name is empty or already registered.
  void registerDriver(String name, QueueDriver driver) {
    _registry.registerDriver(name, driver);
    // Update default driver if this is the first one
    if (_defaultDriver == null) {
      _defaultDriver = driver;
      _defaultDriverName = name;
    }
  }

  /// Sets the default queue driver.
  ///
  /// All queue operations will use this driver unless a specific driver
  /// is requested using the [driver] method.
  ///
  /// Throws [QueueException] if the driver is not registered.
  void setDefaultDriver(String name) {
    _registry.setDefaultDriver(name);
    _defaultDriver = _registry.getDefaultDriver();
    _defaultDriverName = name;
  }

  /// Gets a specific queue driver instance.
  ///
  /// If [name] is provided, returns the driver with that name.
  /// Otherwise, returns the default driver.
  ///
  /// Throws [QueueException] if the requested driver is not registered.
  QueueDriver getDriver([String? name]) {
    if (name != null) {
      final driver = _registry.getDriver(name);
      if (driver == null) {
        throw QueueException('Queue driver "$name" not registered');
      }
      return driver;
    }
    return _registry.getDefaultDriver();
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

  /// Gets all registered driver names.
  List<String> get driverNames => _registry.getDriverNames();

  /// Checks if a driver is registered.
  bool hasDriver(String name) {
    return _registry.hasDriver(name);
  }
}
