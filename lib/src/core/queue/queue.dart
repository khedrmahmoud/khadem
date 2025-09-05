import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import '../../support/queue_drivers/sync_queue_driver.dart';
import '../../support/queue_drivers/memory_queue_driver.dart';

/// Laravel-style Queue facade for simple job dispatching.
/// 
/// Usage:
/// ```dart
/// // Dispatch immediately
/// await Queue.dispatch(SendEmailJob('user@example.com'));
/// 
/// // Dispatch with delay
/// await Queue.dispatch(SendEmailJob('user@example.com'), delay: Duration(minutes: 5));
/// 
/// // Process queued jobs
/// await Queue.work();
/// ```
class Queue {
  static QueueDriver? _driver;
  static String _currentDriver = 'sync';
  
  // Available drivers
  static final Map<String, QueueDriver Function()> _drivers = {
    'sync': () => SyncQueueDriver(),
    'memory': () => MemoryQueueDriver(),
  };

  /// Get the current queue driver
  static QueueDriver get driver {
    if (_driver == null) {
      _driver = _drivers[_currentDriver]!();
    }
    return _driver!;
  }

  /// Set the queue driver (alias for useDriver)
  static void setDriver(String driverName, [QueueDriver? customDriver]) {
    if (customDriver != null) {
      // Register custom driver instance
      _drivers[driverName] = () => customDriver;
    }
    useDriver(driverName);
  }

  /// Set the queue driver
  static void useDriver(String driverName) {
    if (!_drivers.containsKey(driverName)) {
      throw ArgumentError('Unknown queue driver: $driverName. Available: ${_drivers.keys.join(', ')}');
    }
    _currentDriver = driverName;
    _driver = null; // Force recreation
  }

  /// Register a custom driver
  static void registerDriver(String name, QueueDriver Function() factory) {
    _drivers[name] = factory;
  }

  /// Dispatch a job to the queue
  static Future<void> dispatch(QueueJob job, {Duration? delay, String? onQueue}) async {
    try {
      await driver.push(job, delay: delay);
      print('✅ Job dispatched: ${job.displayName}');
    } catch (e) {
      print('❌ Failed to dispatch job: ${job.displayName} - $e');
      rethrow;
    }
  }

  /// Dispatch multiple jobs at once
  static Future<void> dispatchBatch(List<QueueJob> jobs, {Duration? delay}) async {
    for (final job in jobs) {
      await dispatch(job, delay: delay);
    }
  }

  /// Process queued jobs (for non-sync drivers)
  static Future<void> work() async {
    await driver.process();
  }

  /// Process queued jobs (alias for work)
  static Future<void> process() async {
    await work();
  }

  /// Start a worker that continuously processes jobs
  static Future<void> startWorker({
    Duration checkInterval = const Duration(seconds: 1),
    int maxJobs = 100,
    bool verbose = true,
  }) async {
    int processedJobs = 0;
    
    if (verbose) {
      print('🚀 Queue worker started (driver: $_currentDriver)');
    }

    while (processedJobs < maxJobs) {
      try {
        await work();
        processedJobs++;
        
        if (verbose && processedJobs % 10 == 0) {
          print('📊 Processed $processedJobs jobs');
        }
        
        await Future.delayed(checkInterval);
      } catch (e) {
        if (verbose) {
          print('❌ Worker error: $e');
        }
        await Future.delayed(checkInterval);
      }
    }
    
    if (verbose) {
      print('🛑 Queue worker stopped after processing $processedJobs jobs');
    }
  }

  /// Get queue statistics
  static dynamic stats() {
    if (driver is MemoryQueueDriver) {
      final memDriver = driver as MemoryQueueDriver;
      return {
        'driver': _currentDriver,
        'pending_jobs': memDriver.pendingJobsCount,
      };
    } else if (driver.toString().contains('FileQueueDriver')) {
      // Use reflection to call getStats if available
      try {
        final dynamic fileDriver = driver;
        return fileDriver.getStats();
      } catch (e) {
        return {
          'driver': _currentDriver,
          'pending_jobs': 'unknown',
        };
      }
    } else if (driver.toString().contains('RedisQueueDriver')) {
      // Redis stats are async, so we can't return them directly
      return {
        'driver': _currentDriver,
        'pending_jobs': 'async - use redisDriver.getStats()',
      };
    }
    return {
      'driver': _currentDriver,
      'pending_jobs': 'unknown',
    };
  }

  /// Clear all pending jobs (for memory driver)
  static void clear() {
    if (driver is MemoryQueueDriver) {
      (driver as MemoryQueueDriver).clear();
      print('🧹 Queue cleared');
    }
  }
}
