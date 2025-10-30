import 'dart:async';

import '../../../contracts/queue/middleware/index.dart';
import '../../../contracts/queue/queue_driver.dart';
import '../../../contracts/queue/queue_job.dart';
import '../dlq/index.dart';
import '../metrics/queue_metrics.dart';
import '../middleware/index.dart';

/// Job status enumeration
enum JobStatus {
  pending,
  processing,
  completed,
  failed,
  retrying,
  timedOut,
  deadLettered,
}

/// Job context with metadata
class JobContext {
  final String id;
  final QueueJob job;
  final DateTime queuedAt;
  final DateTime? scheduledFor;
  int attempts;
  JobStatus status;
  dynamic error;
  StackTrace? stackTrace;
  final Map<String, dynamic> metadata;

  JobContext({
    required this.id,
    required this.job,
    required this.queuedAt,
    this.scheduledFor,
    this.attempts = 0,
    this.status = JobStatus.pending,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  bool get isReady {
    if (scheduledFor == null) return true;
    return DateTime.now().isAfter(scheduledFor!) ||
        DateTime.now().isAtSameMomentAs(scheduledFor!);
  }

  bool get shouldRetry {
    return job.shouldRetry && attempts < job.maxRetries;
  }

  Duration get processingTime {
    return DateTime.now().difference(queuedAt);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobType': job.runtimeType.toString(),
        'queuedAt': queuedAt.toIso8601String(),
        'scheduledFor': scheduledFor?.toIso8601String(),
        'attempts': attempts,
        'status': status.name,
        'metadata': metadata,
      };
}

/// Configuration for queue drivers
class DriverConfig {
  final String name;
  final bool trackMetrics;
  final bool useDLQ;
  final bool useMiddleware;
  final Duration? defaultJobTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final Map<String, dynamic> driverSpecificConfig;

  const DriverConfig({
    required this.name,
    this.trackMetrics = true,
    this.useDLQ = true,
    this.useMiddleware = true,
    this.defaultJobTimeout,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.driverSpecificConfig = const {},
  });
}

/// Abstract base driver with common functionality
abstract class BaseQueueDriver implements QueueDriver {
  final DriverConfig config;
  final QueueMetrics? metrics;
  final FailedJobHandler? dlqHandler;
  final QueueMiddlewarePipeline? middleware;

  int _jobIdCounter = 0;

  BaseQueueDriver({
    required this.config,
    this.metrics,
    this.dlqHandler,
    this.middleware,
  });

  /// Generate unique job ID
  String generateJobId() {
    return '${config.name}_${DateTime.now().millisecondsSinceEpoch}_${_jobIdCounter++}';
  }

  /// Create job context
  JobContext createJobContext(QueueJob job, {Duration? delay}) {
    final now = DateTime.now();
    return JobContext(
      id: generateJobId(),
      job: job,
      queuedAt: now,
      scheduledFor: delay != null ? now.add(delay) : null,
    );
  }

  /// Execute job with full lifecycle
  Future<void> executeJob(JobContext context) async {
    final startTime = DateTime.now();

    try {
      // Update status
      context.status = JobStatus.processing;
      context.attempts++;

      // Track metrics
      if (metrics != null) {
        metrics!.jobStarted();
      }

      // Execute through middleware pipeline or directly
      if (middleware != null && config.useMiddleware) {
        final middlewareContext = QueueJobContext(
          job: context.job,
          metadata: context.metadata,
        );
        await middleware!.execute(middlewareContext);

        if (middlewareContext.hasError) {
          throw middlewareContext.error;
        }
      } else {
        // Apply timeout if configured
        final timeout = context.job.timeout ?? config.defaultJobTimeout;
        if (timeout != null) {
          await context.job.handle().timeout(timeout);
        } else {
          await context.job.handle();
        }
      }

      // Job succeeded
      context.status = JobStatus.completed;

      if (metrics != null) {
        final processingTime = DateTime.now().difference(startTime);
        metrics!.jobCompleted(
          context.job.runtimeType.toString(),
          processingTime,
        );
      }

      await onJobCompleted(context);
    } on TimeoutException catch (e, stack) {
      context.status = JobStatus.timedOut;
      context.error = e;
      context.stackTrace = stack;

      if (metrics != null) {
        metrics!.jobTimedOut(context.job.runtimeType.toString());
      }

      await handleJobFailure(context);
    } catch (e, stack) {
      context.status = JobStatus.failed;
      context.error = e;
      context.stackTrace = stack;

      if (metrics != null) {
        metrics!.jobFailed(context.job.runtimeType.toString());
      }

      await handleJobFailure(context);
    }
  }

  /// Handle job failure with retry logic
  Future<void> handleJobFailure(JobContext context) async {
    if (context.shouldRetry) {
      // Schedule retry
      context.status = JobStatus.retrying;

      if (metrics != null) {
        metrics!.jobRetried(context.job.runtimeType.toString());
      }

      final retryDelay = context.job.retryDelay;
      await retryJob(context, delay: retryDelay);

      await onJobRetried(context);
    } else {
      // Job failed permanently, send to DLQ
      context.status = JobStatus.deadLettered;

      if (dlqHandler != null && config.useDLQ) {
        await dlqHandler!.recordFailure(
          id: context.id,
          jobType: context.job.runtimeType.toString(),
          payload: context.job.toJson(),
          error: context.error,
          stackTrace: context.stackTrace,
          attempts: context.attempts,
          metadata: context.metadata,
        );
      }

      await onJobFailed(context);
    }
  }

  // =========================================================================
  // Abstract methods that drivers must implement
  // =========================================================================

  /// Retry a failed job
  Future<void> retryJob(JobContext context, {required Duration delay});

  // =========================================================================
  // Lifecycle hooks
  // =========================================================================

  /// Called when a job is successfully completed
  Future<void> onJobCompleted(JobContext context) async {}

  /// Called when a job fails permanently
  Future<void> onJobFailed(JobContext context) async {}

  /// Called when a job is retried
  Future<void> onJobRetried(JobContext context) async {}

  // =========================================================================
  // Utility methods
  // =========================================================================

  /// Get driver statistics
  Future<Map<String, dynamic>> getStats() async {
    final stats = <String, dynamic>{
      'driver': config.name,
      'config': {
        'trackMetrics': config.trackMetrics,
        'useDLQ': config.useDLQ,
        'useMiddleware': config.useMiddleware,
        'maxRetries': config.maxRetries,
        'retryDelay': config.retryDelay.inSeconds,
      },
    };

    if (metrics != null) {
      stats['metrics'] = metrics!.toJson();
    }

    if (dlqHandler != null) {
      stats['dlq'] = await dlqHandler!.dlq.getStats();
    }

    return stats;
  }

  /// Health check
  Future<bool> isHealthy() async => true;

  /// Clear all jobs (for testing)
  Future<void> clear();

  /// Dispose resources
  Future<void> dispose() async {}
}
