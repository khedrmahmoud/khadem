import '../../core/queue/queue_monitor.dart';
import 'queue_job.dart';

/// Interface for queue monitoring and metrics collection.
abstract class QueueMonitor {
  /// Records that a job has been queued.
  void jobQueued(QueueJob job);

  /// Records that a job has started processing.
  void jobStarted(QueueJob job);

  /// Records that a job has completed successfully.
  void jobCompleted(QueueJob job, Duration processingTime);

  /// Records that a job has failed.
  void jobFailed(QueueJob job, dynamic error, Duration processingTime);

  /// Records that a job is being retried.
  void jobRetried(QueueJob job, int attempt);

  /// Gets current queue statistics.
  QueueMetrics getMetrics();

  /// Resets all metrics.
  void reset();
}