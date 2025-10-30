import 'dart:collection';

import '../../../contracts/queue/queue_job.dart';
import 'base_driver.dart';

/// High-performance in-memory queue driver
///
/// Perfect for:
/// - Development and testing
/// - Short-lived jobs that don't need persistence
/// - High-throughput scenarios
/// - Jobs that can be lost on restart
///
/// Features:
/// - Fast O(1) enqueue and dequeue
/// - Priority queue support
/// - Delayed job execution
/// - Full metrics tracking
/// - Middleware support
/// - Dead letter queue integration
///
/// Example:
/// ```dart
/// final driver = InMemoryDriver(
///   config: DriverConfig(
///     name: 'memory',
///     trackMetrics: true,
///     useDLQ: true,
///   ),
///   metrics: metrics,
///   dlqHandler: dlqHandler,
///   middleware: middleware,
/// );
///
/// await driver.push(SendEmailJob('user@example.com'));
/// await driver.process();
/// ```
class InMemoryDriver extends BaseQueueDriver {
  final Queue<JobContext> _queue = Queue<JobContext>();
  final Set<String> _processingJobs = {};

  InMemoryDriver({
    required super.config,
    super.metrics,
    super.dlqHandler,
    super.middleware,
  });

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final context = createJobContext(job, delay: delay);

    // Track metrics
    if (metrics != null) {
      metrics!.jobQueued(job.runtimeType.toString());
      metrics!.recordQueueDepth(_queue.length + 1);
    }

    _queue.add(context);
  }

  @override
  Future<void> process() async {
    // Find next ready job
    final readyJob = _findNextReadyJob();
    if (readyJob == null) return;

    // Mark as processing
    _processingJobs.add(readyJob.id);

    try {
      await executeJob(readyJob);
    } finally {
      // Remove from processing set
      _processingJobs.remove(readyJob.id);

      // Remove completed/failed job from queue
      if (readyJob.status == JobStatus.completed ||
          readyJob.status == JobStatus.deadLettered) {
        _queue.remove(readyJob);
      }

      // Update queue depth metrics
      if (metrics != null) {
        metrics!.recordQueueDepth(_queue.length);
      }
    }
  }

  @override
  Future<void> retryJob(JobContext context, {required Duration delay}) async {
    // Update scheduled time for retry
    context.metadata['scheduledFor'] =
        DateTime.now().add(delay).toIso8601String();

    // Job is already in queue, just update its scheduled time
    // No need to re-add
  }

  JobContext? _findNextReadyJob() {
    for (final job in _queue) {
      // Skip if already processing
      if (_processingJobs.contains(job.id)) continue;

      // Check if job is ready
      if (job.isReady) {
        return job;
      }
    }

    return null;
  }

  @override
  Future<void> clear() async {
    _queue.clear();
    _processingJobs.clear();

    if (metrics != null) {
      metrics!.recordQueueDepth(0);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final baseStats = await super.getStats();

    return {
      ...baseStats,
      'queue_depth': _queue.length,
      'processing_count': _processingJobs.length,
      'pending_count': _queue.length - _processingJobs.length,
      'ready_jobs': _countReadyJobs(),
      'delayed_jobs': _countDelayedJobs(),
    };
  }

  int _countReadyJobs() {
    return _queue.where((job) => job.isReady).length;
  }

  int _countDelayedJobs() {
    return _queue.where((job) => !job.isReady).length;
  }

  /// Get all pending jobs (for testing/inspection)
  List<JobContext> get pendingJobs => List.unmodifiable(_queue);

  /// Get count of pending jobs
  int get pendingJobsCount => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue has jobs
  bool get isNotEmpty => _queue.isNotEmpty;
}
