# Queue System - Simplified Approach

## Overview

The Khadem queue system provides a simple way to dispatch and process jobs asynchronously **without requiring job registration**. Just create your job class, implement the interface, and dispatch it!

## Key Features

- **No Registration Required** - Just implement `QueueJob` and dispatch
- **Multiple Drivers** - File, memory, database, Redis support
- **Batch Processing** - Dispatch multiple jobs at once
- **Monitoring** - Built-in metrics and monitoring
- **Background Workers** - Process jobs in background

## Quick Start

### 1. Create a Job

```dart
class SendEmailJob implements QueueJob {
  final String to;
  final String subject;
  final String body;

  SendEmailJob({required this.to, required this.subject, required this.body});

  @override
  Future<void> handle() async {
    // Your job logic here
    print('📧 Sending email to: $to');
    await _sendEmail(to, subject, body);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'to': to, 'subject': subject, 'body': body};
  }

  @override
  QueueJob fromJson(Map<String, dynamic> json) {
    return SendEmailJob(
      to: json['to'],
      subject: json['subject'], 
      body: json['body'],
    );
  }
}
```

### 2. Dispatch Jobs

```dart
// Get the queue manager
final queueManager = Khadem.queue;

// Dispatch a single job
await queueManager.dispatch(SendEmailJob(
  to: 'user@example.com',
  subject: 'Welcome!',
  body: 'Thanks for joining!',
));

// Dispatch with delay
await queueManager.dispatch(job, delay: Duration(minutes: 5));

// Dispatch multiple jobs at once
await queueManager.dispatchBatch([job1, job2, job3]);
```

### 3. Process Jobs

```dart
// Process jobs (usually done by background workers)
await queueManager.process();

// Or start a background worker
await queueManager.startWorker(
  maxJobs: 10,
  delay: Duration(seconds: 1),
  runInBackground: true,
);
```

## Job Interface

Every job must implement three methods:

```dart
abstract class QueueJob {
  /// Execute the job logic
  Future<void> handle();

  /// Serialize job for storage
  Map<String, dynamic> toJson();

  /// Deserialize job from storage
  QueueJob fromJson(Map<String, dynamic> json);
}
```

## Configuration

Configure queue drivers in your `config/app.json`:

```json
{
  "queue": {
    "driver": "file",
    "run_in_background": true,
    "auto_start": true
  }
}
```

Available drivers:
- `sync` - Execute immediately (for testing)
- `file` - Store jobs in files
- `memory` - Store jobs in memory
- `database` - Store jobs in database
- `redis` - Store jobs in Redis

## Advanced Features

### Job Metadata

Extend `QueueJobWithMetadata` for retry logic and metadata:

```dart
class MyJob extends QueueJobWithMetadata {
  @override
  int get maxAttempts => 3;
  
  @override
  Duration get retryDelay => Duration(seconds: 30);
  
  @override
  Future<void> handle() async {
    // Job logic with automatic retry support
  }
}
```

### Monitoring

Get queue metrics:

```dart
final metrics = queueManager.getMetrics();
print('Jobs processed: ${metrics['jobs_processed']}');
print('Jobs failed: ${metrics['jobs_failed']}');
```

### Error Handling

Handle job failures in workers:

```dart
await queueManager.startWorker(
  onJobError: (job, error, stackTrace) {
    print('Job failed: $error');
    // Log error, send alerts, etc.
  },
  onJobComplete: (job, result) {
    print('Job completed successfully');
  },
);
```

## Benefits of This Approach

1. **Simplicity** - No complex registration system
2. **Self-Contained** - Jobs know how to serialize themselves  
3. **Type Safety** - Jobs are strongly typed
4. **Flexibility** - Easy to create new job types
5. **Testability** - Jobs can be tested independently

## Migration from Complex Systems

If you have existing queue systems with registration:

1. Remove job registration calls
2. Ensure jobs implement `QueueJob` interface
3. Use `queueManager.dispatch(job)` directly
4. Jobs handle their own serialization/deserialization

That's it! No more complex registration patterns or factory functions needed.

## Example: Complete Working Setup

See `example/simple_queue_example.dart` for a complete working example that shows:

- Creating simple job classes
- Dispatching jobs without registration
- Processing jobs with a worker
- Batch processing multiple jobs
- Getting queue metrics

The example demonstrates how much simpler the queue system becomes when you remove the registration complexity!
