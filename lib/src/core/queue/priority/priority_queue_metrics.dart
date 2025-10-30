import 'job_priority.dart';

/// Priority queue statistics and monitoring
class PriorityQueueMetrics {
  final Map<JobPriority, int> _processedByPriority = {};
  final Map<JobPriority, Duration> _totalProcessingTimeByPriority = {};
  final Map<JobPriority, int> _failedByPriority = {};

  void recordJobProcessed(JobPriority priority, Duration processingTime) {
    _processedByPriority[priority] = (_processedByPriority[priority] ?? 0) + 1;
    _totalProcessingTimeByPriority[priority] =
        (_totalProcessingTimeByPriority[priority] ?? Duration.zero) +
            processingTime;
  }

  void recordJobFailed(JobPriority priority) {
    _failedByPriority[priority] = (_failedByPriority[priority] ?? 0) + 1;
  }

  Duration averageProcessingTime(JobPriority priority) {
    final total = _totalProcessingTimeByPriority[priority];
    final count = _processedByPriority[priority];

    if (total == null || count == null || count == 0) {
      return Duration.zero;
    }

    return Duration(microseconds: total.inMicroseconds ~/ count);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    for (final priority in JobPriority.values) {
      result[priority.name] = {
        'processed': _processedByPriority[priority] ?? 0,
        'failed': _failedByPriority[priority] ?? 0,
        'averageProcessingTimeMs':
            averageProcessingTime(priority).inMilliseconds,
      };
    }

    return result;
  }

  void reset() {
    _processedByPriority.clear();
    _totalProcessingTimeByPriority.clear();
    _failedByPriority.clear();
  }
}
