# Khadem Queue System

A robust, scalable queue system for the Khadem framework with support for multiple drivers, job serialization, monitoring, and proper separation of concerns.

## Features

- **Multiple Queue Drivers**: Support for in-memory, file-based, Redis, and synchronous queues
- **Job Serialization**: Automatic JSON serialization/deserialization of jobs
- **Job Retry Logic**: Configurable retry policies with exponential backoff
- **Queue Monitoring**: Comprehensive metrics and statistics collection
- **Worker Management**: Background job processing with configurable workers
- **Error Handling**: Robust error handling that prevents queue failures from crashing the application
- **Extensible Architecture**: Easy to add new drivers and job types

## Architecture

The queue system is built with clear separation of concerns:

- **`QueueFactory`**: Manages driver registration and resolution
- **`QueueDriverRegistry`**: Centralized registry for queue drivers
- **`QueueJobSerializer`**: Handles job serialization/deserialization
- **`QueueManager`**: Main interface for queue operations
- **`QueueWorker`**: Handles job processing with proper error handling
- **`QueueMonitor`**: Collects metrics and statistics
- **`QueueJob`**: Base class for jobs with retry and metadata support

## Quick Start

### Basic Usage

```dart
import 'package:khadem/src/core/queue/queue_manager.dart';
import 'package:khadem/src/core/queue/queue_factory.dart';

// Create a job
class SendEmailJob extends QueueJob {
  final String email;
  final String message;

  SendEmailJob(this.email, this.message);

  @override
  Future<void> handle() async {
    // Send email logic here
    print('Sending email to $email: $message');
  }

  @override
  Map<String, dynamic> toJson() => {
    'email': email,
    'message': message,
  };

  @override
  SendEmailJob fromJson(Map<String, dynamic> json) => SendEmailJob(
    json['email'],
    json['message'],
  );
}

// Register the job factory
QueueFactory.registerJobFactory('SendEmailJob', (json) => SendEmailJob.fromJson(json));

// Initialize queue manager
final config = AppConfig(); // Your config
final queueManager = QueueManager(config);
await queueManager.init();

// Dispatch a job
final job = SendEmailJob('user@example.com', 'Hello World!');
await queueManager.dispatch(job);

// Start a worker to process jobs
await queueManager.startWorker();
```

### Configuration

Configure the queue system in your application config:

```dart
// config/app.dart or similar
return {
  'queue': {
    'driver': 'memory', // sync, memory, file, redis
    'workers': {
      'max_jobs': 100,
      'delay': 1, // seconds
      'timeout': 3600, // seconds
    },
  },
};
```

## Queue Drivers

### Synchronous Driver (`sync`)

Executes jobs immediately without queuing:

```dart
'queue': {
  'driver': 'sync',
}
```

### In-Memory Driver (`memory`)

Stores jobs in memory (good for development/testing):

```dart
'queue': {
  'driver': 'memory',
}
```

### File Driver (`file`)

Persists jobs to files (good for simple persistence):

```dart
'queue': {
  'driver': 'file',
  'path': 'storage/queue/jobs.json',
}
```

### Redis Driver (`redis`)

Uses Redis for distributed queuing (production-ready):

```dart
'queue': {
  'driver': 'redis',
  'host': 'localhost',
  'port': 6379,
  'password': 'your-password',
}
```

## Job Management

### Creating Jobs

```dart
class ProcessOrderJob extends QueueJob {
  final String orderId;
  final double amount;

  ProcessOrderJob(this.orderId, this.amount);

  @override
  Future<void> handle() async {
    // Process order logic
    await processPayment(orderId, amount);
    await updateInventory(orderId);
    await sendConfirmation(orderId);
  }

  @override
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'amount': amount,
  };

  @override
  ProcessOrderJob fromJson(Map<String, dynamic> json) => ProcessOrderJob(
    json['orderId'],
    json['amount'],
  );
}
```

### Registering Jobs

```dart
// Register job factory
QueueFactory.registerJobFactory('ProcessOrderJob', (json) => ProcessOrderJob.fromJson(json));

// Or register directly in job constructor
class ProcessOrderJob extends QueueJob {
  // ... constructor and methods ...

  ProcessOrderJob() {
    QueueFactory.registerJobFactory('ProcessOrderJob', (json) => fromJson(json));
  }
}
```

### Dispatching Jobs

```dart
// Dispatch immediately
await queueManager.dispatch(ProcessOrderJob('order-123', 99.99));

// Dispatch with delay
await queueManager.dispatch(
  ProcessOrderJob('order-456', 149.99),
  delay: Duration(minutes: 5),
);
```

## Worker Management

### Starting Workers

```dart
// Start a basic worker
await queueManager.startWorker();

// Start worker with custom configuration
await queueManager.startWorker(
  maxJobs: 1000,                    // Stop after 1000 jobs
  delay: Duration(milliseconds: 500), // Check every 500ms
  timeout: Duration(hours: 1),       // Stop after 1 hour
  runInBackground: true,             // Run in background
  onError: (error, stack) {
    print('Worker error: $error');
  },
);
```

### Worker Configuration Options

- **`maxJobs`**: Maximum number of jobs to process before stopping
- **`delay`**: Delay between job processing attempts
- **`timeout`**: Maximum runtime before stopping
- **`runInBackground`**: Whether to run in background or block
- **`onError`**: Error handler for worker errors
- **`onJobStart`**: Callback when job starts
- **`onJobComplete`**: Callback when job completes
- **`onJobError`**: Callback when job fails

## Job Retry and Error Handling

### Basic Retry Logic

```dart
class RetryableJob extends QueueJobWithMetadata {
  @override
  int get maxAttempts => 3;

  @override
  Duration get retryDelay => Duration(seconds: 30);

  @override
  Future<void> handle() async {
    // Job logic that might fail
    await riskyOperation();
  }

  @override
  Map<String, dynamic> toJson() => {
    'attempt': attempt,
    'created_at': createdAt?.toIso8601String(),
    // ... other fields
  };

  @override
  void fromJsonWithMetadata(Map<String, dynamic> json) {
    attempt = json['attempt'] ?? 0;
    createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null;
  }
}
```

### Custom Retry Policies

```dart
class CustomRetryJob extends QueueJobWithMetadata {
  @override
  int get maxAttempts => 5;

  @override
  Duration get retryDelay => Duration(minutes: 1);

  @override
  bool get shouldRetry => true;

  @override
  int get priority => 10; // Higher priority

  @override
  Duration getNextRetryDelay() {
    // Custom backoff strategy
    return retryDelay * (attempt * attempt); // Exponential backoff
  }
}
```

## Monitoring and Metrics

### Getting Queue Metrics

```dart
final metrics = queueManager.getMetrics();

print('Jobs processed: ${metrics['total_completed']}');
print('Jobs failed: ${metrics['total_failed']}');
print('Success rate: ${metrics['success_rate']}');
print('Average processing time: ${metrics['average_processing_time_ms']}ms');
```

### Available Metrics

- **`total_queued`**: Total jobs queued
- **`total_started`**: Total jobs started processing
- **`total_completed`**: Total jobs completed successfully
- **`total_failed`**: Total jobs that failed
- **`total_retried`**: Total jobs retried
- **`currently_processing`**: Jobs currently being processed
- **`success_rate`**: Ratio of completed to total jobs
- **`failure_rate`**: Ratio of failed to total jobs
- **`average_processing_time_ms`**: Average job processing time

### Resetting Metrics

```dart
queueManager.resetMetrics();
```

## Advanced Usage

### Custom Queue Drivers

```dart
class CustomQueueDriver implements QueueDriver {
  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    // Custom queuing logic
  }

  @override
  Future<void> process() async {
    // Custom processing logic
  }
}

// Register custom driver
QueueFactory.registerDriver('custom', CustomQueueDriver());
```

### Job Middleware

```dart
class LoggingMiddleware {
  Future<void> handle(QueueJob job, Future<void> Function() next) async {
    print('Starting job: ${job.runtimeType}');
    final start = DateTime.now();

    try {
      await next();
      final duration = DateTime.now().difference(start);
      print('Completed job: ${job.runtimeType} in ${duration.inMilliseconds}ms');
    } catch (e) {
      print('Failed job: ${job.runtimeType} - $e');
      rethrow;
    }
  }
}
```

### Batch Job Processing

```dart
class BatchProcessJob extends QueueJob {
  final List<String> items;

  BatchProcessJob(this.items);

  @override
  Future<void> handle() async {
    for (final item in items) {
      await processItem(item);
    }
  }

  Future<void> processItem(String item) async {
    // Process individual item
  }
}
```

## Best Practices

### 1. Job Design

- Keep jobs small and focused on a single responsibility
- Make jobs idempotent (safe to run multiple times)
- Include all necessary data in job serialization
- Handle errors gracefully within jobs

### 2. Worker Configuration

```dart
// Production configuration
await queueManager.startWorker(
  maxJobs: 10000,              // Process many jobs
  delay: Duration(seconds: 1),  // Check frequently
  timeout: null,                // Run indefinitely
  runInBackground: true,        // Don't block main thread
  onError: (error, stack) {
    // Log to monitoring system
    monitoring.reportError(error, stack);
  },
);
```

### 3. Error Handling

```dart
class RobustJob extends QueueJobWithMetadata {
  @override
  Future<void> handle() async {
    try {
      await riskyOperation();
    } catch (e) {
      // Log error but don't rethrow
      await logError(e);

      // Re-throw to trigger retry logic
      throw JobProcessingException('Failed to process job: $e');
    }
  }

  Future<void> logError(dynamic error) async {
    // Log to external service
  }
}
```

### 4. Monitoring

```dart
// Periodic health check
Timer.periodic(Duration(minutes: 5), (timer) async {
  final metrics = queueManager.getMetrics();

  if (metrics['failure_rate'] > 0.1) { // More than 10% failure rate
    await alertSystem.sendAlert('High queue failure rate detected');
  }

  if (metrics['currently_processing'] > 100) { // Too many jobs processing
    await alertSystem.sendAlert('Queue backlog detected');
  }
});
```

### 5. Resource Management

```dart
class ResourceAwareJob extends QueueJob {
  @override
  Future<void> handle() async {
    // Use resource management
    final connection = await database.getConnection();
    try {
      await connection.execute('UPDATE users SET processed = true WHERE id = ?', [userId]);
    } finally {
      connection.close(); // Always clean up
    }
  }
}
```

## Testing

The queue system includes comprehensive tests:

```bash
# Run all queue tests
dart test test/core/queue/

# Run specific test files
dart test test/core/queue/queue_manager_test.dart
dart test test/core/queue/queue_factory_test.dart
```

### Testing Jobs

```dart
void main() {
  test('should process job successfully', () async {
    final job = TestJob('test-data');

    // Register factory for deserialization
    QueueFactory.registerJobFactory('TestJob', (json) => TestJob.fromJson(json));

    // Test job execution
    await job.handle();

    // Verify job effects
    expect(someService.wasCalled, isTrue);
  });
}
```

### Testing Queue Operations

```dart
void main() {
  late QueueManager queueManager;

  setUp(() async {
    final config = MockConfig();
    queueManager = QueueManager(config);
    await queueManager.init();
  });

  test('should dispatch job to queue', () async {
    final job = TestJob('test');

    await queueManager.dispatch(job);

    // Verify job was queued
    expect(queueManager.getMetrics()['total_queued'], equals(1));
  });
}
```

## Troubleshooting

### Common Issues

1. **Jobs not processing**: Check if worker is running and driver is configured correctly
2. **Jobs failing repeatedly**: Check job error handling and retry logic
3. **Memory issues**: Monitor queue size and implement job cleanup
4. **Performance problems**: Check worker configuration and job processing time

### Debug Mode

Enable detailed logging for troubleshooting:

```dart
final queueManager = QueueManager(config, monitor: BasicQueueMonitor());

// Log all queue events
queueManager.monitor; // Access metrics

// Custom error handling
await queueManager.startWorker(
  onError: (error, stack) {
    print('Queue error: $error');
    print('Stack trace: $stack');
  },
  onJobStart: (job) {
    print('Started job: ${job.runtimeType}');
  },
  onJobComplete: (job, result) {
    print('Completed job: ${job.runtimeType}');
  },
  onJobError: (job, error, stack) {
    print('Failed job: ${job.runtimeType} - $error');
  },
);
```

## Performance Considerations

- **Driver Selection**: Choose appropriate driver based on use case
- **Worker Tuning**: Adjust worker settings based on load
- **Job Size**: Keep jobs small to prevent memory issues
- **Monitoring**: Regularly monitor queue metrics
- **Cleanup**: Implement job cleanup for completed/failed jobs

## Migration Guide

### From Other Queue Systems

1. **Update imports**: Replace old queue imports with Khadem queue imports
2. **Update job classes**: Extend `QueueJob` instead of old base class
3. **Update configuration**: Use new configuration format
4. **Update worker code**: Use new worker API
5. **Test thoroughly**: Run comprehensive tests before deploying

### Version Compatibility

- **v1.0+**: Full feature set with all drivers
- **v0.5+**: Basic queue functionality
- **v0.1+**: Initial release with sync and memory drivers

This queue system provides a solid foundation for background job processing in Dart applications, with proper separation of concerns, comprehensive testing, and production-ready features.</content>
<parameter name="filePath">d:\Users\Khedr\src\khadem\lib\src\core\queue\README.md
