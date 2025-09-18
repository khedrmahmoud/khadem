import '../../contracts/queue/queue_job.dart';
import '../../contracts/queue/queue_monitor.dart';



/// Basic implementation of queue monitoring.
class BasicQueueMonitor implements QueueMonitor {
  final QueueMetrics _metrics = QueueMetrics();

  @override
  void jobQueued(QueueJob job) {
    _metrics.totalQueued++;
    _metrics.queuedByType[job.runtimeType.toString()] =
        (_metrics.queuedByType[job.runtimeType.toString()] ?? 0) + 1;
  }

  @override
  void jobStarted(QueueJob job) {
    _metrics.totalStarted++;
    _metrics.currentlyProcessing++;
  }

  @override
  void jobCompleted(QueueJob job, Duration processingTime) {
    _metrics.totalCompleted++;
    _metrics.currentlyProcessing--;
    _metrics.totalProcessingTime += processingTime;
    _metrics.completedByType[job.runtimeType.toString()] =
        (_metrics.completedByType[job.runtimeType.toString()] ?? 0) + 1;
  }

  @override
  void jobFailed(QueueJob job, dynamic error, Duration processingTime) {
    _metrics.totalFailed++;
    _metrics.currentlyProcessing--;
    _metrics.totalProcessingTime += processingTime;
    _metrics.failedByType[job.runtimeType.toString()] =
        (_metrics.failedByType[job.runtimeType.toString()] ?? 0) + 1;
  }

  @override
  void jobRetried(QueueJob job, int attempt) {
    _metrics.totalRetried++;
    _metrics.retriedByType[job.runtimeType.toString()] =
        (_metrics.retriedByType[job.runtimeType.toString()] ?? 0) + 1;
  }

  @override
  QueueMetrics getMetrics() => _metrics;

  @override
  void reset() {
    _metrics.reset();
  }
}

/// Comprehensive queue metrics.
class QueueMetrics {
  int totalQueued = 0;
  int totalStarted = 0;
  int totalCompleted = 0;
  int totalFailed = 0;
  int totalRetried = 0;
  int currentlyProcessing = 0;
  Duration totalProcessingTime = Duration.zero;

  final Map<String, int> queuedByType = {};
  final Map<String, int> completedByType = {};
  final Map<String, int> failedByType = {};
  final Map<String, int> retriedByType = {};

  double get successRate {
    if (totalCompleted + totalFailed == 0) return 0.0;
    return totalCompleted / (totalCompleted + totalFailed);
  }

  double get failureRate {
    if (totalCompleted + totalFailed == 0) return 0.0;
    return totalFailed / (totalCompleted + totalFailed);
  }

  Duration get averageProcessingTime {
    if (totalCompleted == 0) return Duration.zero;
    return Duration(microseconds: totalProcessingTime.inMicroseconds ~/ totalCompleted);
  }

  void reset() {
    totalQueued = 0;
    totalStarted = 0;
    totalCompleted = 0;
    totalFailed = 0;
    totalRetried = 0;
    currentlyProcessing = 0;
    totalProcessingTime = Duration.zero;
    queuedByType.clear();
    completedByType.clear();
    failedByType.clear();
    retriedByType.clear();
  }

  Map<String, dynamic> toJson() {
    return {
      'total_queued': totalQueued,
      'total_started': totalStarted,
      'total_completed': totalCompleted,
      'total_failed': totalFailed,
      'total_retried': totalRetried,
      'currently_processing': currentlyProcessing,
      'total_processing_time_ms': totalProcessingTime.inMilliseconds,
      'success_rate': successRate,
      'failure_rate': failureRate,
      'average_processing_time_ms': averageProcessingTime.inMilliseconds,
      'queued_by_type': queuedByType,
      'completed_by_type': completedByType,
      'failed_by_type': failedByType,
      'retried_by_type': retriedByType,
    };
  }
}
