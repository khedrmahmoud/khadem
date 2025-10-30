/// Interface for queue metrics collection
abstract interface class QueueMetricsContract {
  /// Record job queued
  void jobQueued(String jobType);

  /// Record job started
  void jobStarted();

  /// Record job completed
  void jobCompleted(String jobType, Duration processingTime);

  /// Record job failed
  void jobFailed(String jobType);

  /// Record job retried
  void jobRetried(String jobType);

  /// Record job timed out
  void jobTimedOut(String jobType);

  /// Record queue depth snapshot
  void recordQueueDepth(int depth);

  /// Get success rate (0.0 to 1.0)
  double get successRate;

  /// Get failure rate (0.0 to 1.0)
  double get failureRate;

  /// Get average processing time
  Duration get averageProcessingTime;

  /// Get throughput (jobs per second)
  double get throughput;

  /// Reset all metrics
  void reset();

  /// Export metrics as JSON
  Map<String, dynamic> toJson();
}
