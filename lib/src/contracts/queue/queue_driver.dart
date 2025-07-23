import 'queue_job.dart';

/// Defines the core interface for any queue driver implementation.
///
/// A queue driver is responsible for pushing jobs into a queue and processing them.
/// Implement this interface for custom drivers like Redis, Database, In-Memory, etc.
abstract interface class QueueDriver {
  /// Pushes a [QueueJob] to the queue with optional [delay].
  ///
  /// The delay allows deferring the job execution.
  ///
  /// Example:
  /// ```dart
  /// await queueDriver.push(SendEmailJob(), delay: Duration(seconds: 30));
  /// ```
  Future<void> push(QueueJob job, {Duration? delay});

  /// Starts processing queued jobs.
  ///
  /// This method is typically used in a worker loop.
  ///
  /// Example:
  /// ```dart
  /// await queueDriver.process(); // start the worker
  /// ```
  Future<void> process();
}
