import 'dart:collection';
import 'dart:math';

import '../priority/job_priority.dart';

/// Comprehensive queue metrics with detailed statistics
class QueueMetrics {
  // Counters
  int totalQueued = 0;
  int totalStarted = 0;
  int totalCompleted = 0;
  int totalFailed = 0;
  int totalRetried = 0;
  int totalTimedOut = 0;
  int currentlyProcessing = 0;

  // Timing
  DateTime? startTime;
  DateTime? lastActivity;
  final List<Duration> _processingTimes = [];
  final int _maxSamples = 10000;

  // Per-type statistics
  final Map<String, int> queuedByType = {};
  final Map<String, int> completedByType = {};
  final Map<String, int> failedByType = {};
  final Map<String, int> retriedByType = {};
  final Map<String, Duration> totalProcessingTimeByType = {};

  // Per-priority statistics
  final Map<JobPriority, int> queuedByPriority = {};
  final Map<JobPriority, int> completedByPriority = {};
  final Map<JobPriority, int> failedByPriority = {};

  // Queue depth tracking
  final Queue<_QueueDepthSnapshot> _queueDepthHistory = Queue();
  final int _maxDepthSnapshots = 1000;

  // Worker utilization
  final Queue<_WorkerUtilization> _utilizationHistory = Queue();
  final int _maxUtilizationSnapshots = 1000;
  int _totalWorkers = 0;

  /// Record job queued
  void jobQueued(String jobType, {JobPriority? priority}) {
    totalQueued++;
    lastActivity = DateTime.now();
    queuedByType[jobType] = (queuedByType[jobType] ?? 0) + 1;

    if (priority != null) {
      queuedByPriority[priority] = (queuedByPriority[priority] ?? 0) + 1;
    }
  }

  /// Record job started
  void jobStarted() {
    totalStarted++;
    currentlyProcessing++;
    lastActivity = DateTime.now();
  }

  /// Record job completed
  void jobCompleted(
    String jobType,
    Duration processingTime, {
    JobPriority? priority,
  }) {
    totalCompleted++;
    currentlyProcessing--;
    lastActivity = DateTime.now();

    completedByType[jobType] = (completedByType[jobType] ?? 0) + 1;

    totalProcessingTimeByType[jobType] =
        (totalProcessingTimeByType[jobType] ?? Duration.zero) + processingTime;

    _recordProcessingTime(processingTime);

    if (priority != null) {
      completedByPriority[priority] = (completedByPriority[priority] ?? 0) + 1;
    }
  }

  /// Record job failed
  void jobFailed(String jobType, {JobPriority? priority}) {
    totalFailed++;
    currentlyProcessing--;
    lastActivity = DateTime.now();

    failedByType[jobType] = (failedByType[jobType] ?? 0) + 1;

    if (priority != null) {
      failedByPriority[priority] = (failedByPriority[priority] ?? 0) + 1;
    }
  }

  /// Record job retried
  void jobRetried(String jobType) {
    totalRetried++;
    lastActivity = DateTime.now();
    retriedByType[jobType] = (retriedByType[jobType] ?? 0) + 1;
  }

  /// Record job timed out
  void jobTimedOut(String jobType) {
    totalTimedOut++;
    currentlyProcessing--;
    lastActivity = DateTime.now();
  }

  /// Record queue depth snapshot
  void recordQueueDepth(int depth) {
    _queueDepthHistory.add(
      _QueueDepthSnapshot(
        timestamp: DateTime.now(),
        depth: depth,
      ),
    );

    if (_queueDepthHistory.length > _maxDepthSnapshots) {
      _queueDepthHistory.removeFirst();
    }
  }

  /// Record worker utilization
  void recordWorkerUtilization(int activeWorkers, int totalWorkers) {
    _totalWorkers = totalWorkers;
    _utilizationHistory.add(
      _WorkerUtilization(
        timestamp: DateTime.now(),
        activeWorkers: activeWorkers,
        totalWorkers: totalWorkers,
      ),
    );

    if (_utilizationHistory.length > _maxUtilizationSnapshots) {
      _utilizationHistory.removeFirst();
    }
  }

  void _recordProcessingTime(Duration duration) {
    _processingTimes.add(duration);
    if (_processingTimes.length > _maxSamples) {
      _processingTimes.removeAt(0);
    }
  }

  // =========================================================================
  // Computed Metrics
  // =========================================================================

  /// Uptime since metrics started
  Duration get uptime {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }

  /// Success rate (0.0 to 1.0)
  double get successRate {
    final total = totalCompleted + totalFailed;
    if (total == 0) return 0.0;
    return totalCompleted / total;
  }

  /// Failure rate (0.0 to 1.0)
  double get failureRate {
    final total = totalCompleted + totalFailed;
    if (total == 0) return 0.0;
    return totalFailed / total;
  }

  /// Timeout rate (0.0 to 1.0)
  double get timeoutRate {
    if (totalStarted == 0) return 0.0;
    return totalTimedOut / totalStarted;
  }

  /// Average processing time
  Duration get averageProcessingTime {
    if (_processingTimes.isEmpty) return Duration.zero;
    final totalMs = _processingTimes.fold<int>(
      0,
      (sum, d) => sum + d.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _processingTimes.length);
  }

  /// Median processing time (P50)
  Duration get p50ProcessingTime => _percentile(0.5);

  /// P95 processing time
  Duration get p95ProcessingTime => _percentile(0.95);

  /// P99 processing time
  Duration get p99ProcessingTime => _percentile(0.99);

  /// P999 processing time
  Duration get p999ProcessingTime => _percentile(0.999);

  /// Min processing time
  Duration get minProcessingTime {
    if (_processingTimes.isEmpty) return Duration.zero;
    return _processingTimes.reduce((a, b) => a < b ? a : b);
  }

  /// Max processing time
  Duration get maxProcessingTime {
    if (_processingTimes.isEmpty) return Duration.zero;
    return _processingTimes.reduce((a, b) => a > b ? a : b);
  }

  /// Standard deviation of processing times
  Duration get stdDevProcessingTime {
    if (_processingTimes.isEmpty) return Duration.zero;

    final avg = averageProcessingTime.inMilliseconds;
    final variance = _processingTimes.fold<double>(
          0.0,
          (sum, d) {
            final diff = d.inMilliseconds - avg;
            return sum + (diff * diff);
          },
        ) /
        _processingTimes.length;

    return Duration(milliseconds: sqrt(variance).round());
  }

  /// Throughput (jobs per second)
  double get throughput {
    if (startTime == null) return 0.0;
    final uptimeSeconds = uptime.inSeconds;
    if (uptimeSeconds == 0) return 0.0;
    return totalCompleted / uptimeSeconds;
  }

  /// Average queue depth (from snapshots)
  double get averageQueueDepth {
    if (_queueDepthHistory.isEmpty) return 0.0;
    final total = _queueDepthHistory.fold<int>(0, (sum, s) => sum + s.depth);
    return total / _queueDepthHistory.length;
  }

  /// Current queue depth (most recent snapshot)
  int get currentQueueDepth {
    if (_queueDepthHistory.isEmpty) return 0;
    return _queueDepthHistory.last.depth;
  }

  /// Peak queue depth
  int get peakQueueDepth {
    if (_queueDepthHistory.isEmpty) return 0;
    return _queueDepthHistory.fold<int>(
      0,
      (max, s) => s.depth > max ? s.depth : max,
    );
  }

  /// Average worker utilization (0.0 to 1.0)
  double get averageWorkerUtilization {
    if (_utilizationHistory.isEmpty) return 0.0;
    final total = _utilizationHistory.fold<double>(
      0.0,
      (sum, u) => sum + u.utilization,
    );
    return total / _utilizationHistory.length;
  }

  /// Current worker utilization
  double get currentWorkerUtilization {
    if (_utilizationHistory.isEmpty) return 0.0;
    return _utilizationHistory.last.utilization;
  }

  /// Peak worker utilization
  double get peakWorkerUtilization {
    if (_utilizationHistory.isEmpty) return 0.0;
    return _utilizationHistory.fold<double>(
      0.0,
      (max, u) => u.utilization > max ? u.utilization : max,
    );
  }

  Duration _percentile(double percentile) {
    if (_processingTimes.isEmpty) return Duration.zero;
    final sorted = List<Duration>.from(_processingTimes)
      ..sort((a, b) => a.inMilliseconds.compareTo(b.inMilliseconds));
    final index = (sorted.length * percentile).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Get average processing time for a specific job type
  Duration averageProcessingTimeForType(String jobType) {
    final total = totalProcessingTimeByType[jobType];
    final count = completedByType[jobType];

    if (total == null || count == null || count == 0) {
      return Duration.zero;
    }

    return Duration(microseconds: total.inMicroseconds ~/ count);
  }

  /// Reset all metrics
  void reset() {
    totalQueued = 0;
    totalStarted = 0;
    totalCompleted = 0;
    totalFailed = 0;
    totalRetried = 0;
    totalTimedOut = 0;
    currentlyProcessing = 0;
    startTime = null;
    lastActivity = null;

    _processingTimes.clear();
    queuedByType.clear();
    completedByType.clear();
    failedByType.clear();
    retriedByType.clear();
    totalProcessingTimeByType.clear();
    queuedByPriority.clear();
    completedByPriority.clear();
    failedByPriority.clear();
    _queueDepthHistory.clear();
    _utilizationHistory.clear();
  }

  /// Export metrics as JSON
  Map<String, dynamic> toJson() {
    return {
      // Counters
      'total_queued': totalQueued,
      'total_started': totalStarted,
      'total_completed': totalCompleted,
      'total_failed': totalFailed,
      'total_retried': totalRetried,
      'total_timed_out': totalTimedOut,
      'currently_processing': currentlyProcessing,

      // Rates
      'success_rate': successRate,
      'failure_rate': failureRate,
      'timeout_rate': timeoutRate,
      'throughput_per_second': throughput,

      // Processing times
      'average_processing_time_ms': averageProcessingTime.inMilliseconds,
      'p50_processing_time_ms': p50ProcessingTime.inMilliseconds,
      'p95_processing_time_ms': p95ProcessingTime.inMilliseconds,
      'p99_processing_time_ms': p99ProcessingTime.inMilliseconds,
      'p999_processing_time_ms': p999ProcessingTime.inMilliseconds,
      'min_processing_time_ms': minProcessingTime.inMilliseconds,
      'max_processing_time_ms': maxProcessingTime.inMilliseconds,
      'std_dev_processing_time_ms': stdDevProcessingTime.inMilliseconds,

      // Queue depth
      'current_queue_depth': currentQueueDepth,
      'average_queue_depth': averageQueueDepth,
      'peak_queue_depth': peakQueueDepth,

      // Worker utilization
      'total_workers': _totalWorkers,
      'current_worker_utilization': currentWorkerUtilization,
      'average_worker_utilization': averageWorkerUtilization,
      'peak_worker_utilization': peakWorkerUtilization,

      // Timing
      'uptime_seconds': uptime.inSeconds,
      'start_time': startTime?.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),

      // Per-type statistics
      'queued_by_type': queuedByType,
      'completed_by_type': completedByType,
      'failed_by_type': failedByType,
      'retried_by_type': retriedByType,
      'average_processing_time_by_type': totalProcessingTimeByType.map(
        (k, v) => MapEntry(k, averageProcessingTimeForType(k).inMilliseconds),
      ),

      // Per-priority statistics
      'queued_by_priority': _priorityMapToJson(queuedByPriority),
      'completed_by_priority': _priorityMapToJson(completedByPriority),
      'failed_by_priority': _priorityMapToJson(failedByPriority),
    };
  }

  Map<String, int> _priorityMapToJson(Map<JobPriority, int> map) {
    return map.map((k, v) => MapEntry(k.name, v));
  }

  /// Export metrics in Prometheus format
  String toPrometheusFormat({String prefix = 'queue'}) {
    final buffer = StringBuffer();

    buffer.writeln('# HELP ${prefix}_total_queued Total number of jobs queued');
    buffer.writeln('# TYPE ${prefix}_total_queued counter');
    buffer.writeln('${prefix}_total_queued $totalQueued');

    buffer.writeln(
        '# HELP ${prefix}_total_completed Total number of jobs completed',);
    buffer.writeln('# TYPE ${prefix}_total_completed counter');
    buffer.writeln('${prefix}_total_completed $totalCompleted');

    buffer.writeln('# HELP ${prefix}_total_failed Total number of jobs failed');
    buffer.writeln('# TYPE ${prefix}_total_failed counter');
    buffer.writeln('${prefix}_total_failed $totalFailed');

    buffer.writeln(
        '# HELP ${prefix}_currently_processing Number of jobs currently processing',);
    buffer.writeln('# TYPE ${prefix}_currently_processing gauge');
    buffer.writeln('${prefix}_currently_processing $currentlyProcessing');

    buffer.writeln('# HELP ${prefix}_throughput Jobs processed per second');
    buffer.writeln('# TYPE ${prefix}_throughput gauge');
    buffer.writeln('${prefix}_throughput $throughput');

    buffer.writeln(
        '# HELP ${prefix}_processing_time_seconds Job processing time',);
    buffer.writeln('# TYPE ${prefix}_processing_time_seconds summary');
    buffer.writeln(
        '${prefix}_processing_time_seconds{quantile="0.5"} ${p50ProcessingTime.inMilliseconds / 1000}',);
    buffer.writeln(
        '${prefix}_processing_time_seconds{quantile="0.95"} ${p95ProcessingTime.inMilliseconds / 1000}',);
    buffer.writeln(
        '${prefix}_processing_time_seconds{quantile="0.99"} ${p99ProcessingTime.inMilliseconds / 1000}',);

    buffer.writeln('# HELP ${prefix}_queue_depth Current queue depth');
    buffer.writeln('# TYPE ${prefix}_queue_depth gauge');
    buffer.writeln('${prefix}_queue_depth $currentQueueDepth');

    buffer.writeln(
        '# HELP ${prefix}_worker_utilization Worker utilization (0-1)',);
    buffer.writeln('# TYPE ${prefix}_worker_utilization gauge');
    buffer.writeln('${prefix}_worker_utilization $currentWorkerUtilization');

    return buffer.toString();
  }
}

/// Queue depth snapshot
class _QueueDepthSnapshot {
  final DateTime timestamp;
  final int depth;

  _QueueDepthSnapshot({required this.timestamp, required this.depth});
}

/// Worker utilization snapshot
class _WorkerUtilization {
  final DateTime timestamp;
  final int activeWorkers;
  final int totalWorkers;

  _WorkerUtilization({
    required this.timestamp,
    required this.activeWorkers,
    required this.totalWorkers,
  });

  double get utilization {
    if (totalWorkers == 0) return 0.0;
    return activeWorkers / totalWorkers;
  }
}
