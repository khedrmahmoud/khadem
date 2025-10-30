import 'package:khadem/src/core/queue/metrics/index.dart';
import 'package:khadem/src/core/queue/priority/index.dart';
import 'package:test/test.dart';

void main() {
  group('QueueMetrics', () {
    late QueueMetrics metrics;

    setUp(() {
      metrics = QueueMetrics();
      metrics.startTime = DateTime.now();
    });

    test('should track basic counters', () {
      metrics.jobQueued('TestJob');
      metrics.jobQueued('TestJob');
      metrics.jobQueued('AnotherJob');

      expect(metrics.totalQueued, equals(3));
      expect(metrics.queuedByType['TestJob'], equals(2));
      expect(metrics.queuedByType['AnotherJob'], equals(1));
    });

    test('should track job lifecycle', () {
      metrics.jobQueued('TestJob');
      metrics.jobStarted();
      metrics.jobCompleted('TestJob', const Duration(milliseconds: 100));

      expect(metrics.totalQueued, equals(1));
      expect(metrics.totalStarted, equals(1));
      expect(metrics.totalCompleted, equals(1));
      expect(metrics.currentlyProcessing, equals(0));
    });

    test('should track failures', () {
      metrics.jobQueued('FailJob');
      metrics.jobStarted();
      metrics.jobFailed('FailJob');

      expect(metrics.totalFailed, equals(1));
      expect(metrics.failedByType['FailJob'], equals(1));
      expect(metrics.currentlyProcessing, equals(0));
    });

    test('should track retries', () {
      metrics.jobRetried('TestJob');
      metrics.jobRetried('TestJob');

      expect(metrics.totalRetried, equals(2));
      expect(metrics.retriedByType['TestJob'], equals(2));
    });

    test('should track timeouts', () {
      metrics.jobQueued('SlowJob');
      metrics.jobStarted();
      metrics.jobTimedOut('SlowJob');

      expect(metrics.totalTimedOut, equals(1));
      expect(metrics.currentlyProcessing, equals(0));
    });

    test('should calculate success rate', () {
      metrics.jobCompleted('Job1', const Duration(milliseconds: 10));
      metrics.jobCompleted('Job2', const Duration(milliseconds: 10));
      metrics.jobCompleted('Job3', const Duration(milliseconds: 10));
      metrics.jobFailed('Job4');

      expect(metrics.successRate, closeTo(0.75, 0.01)); // 3/4 = 0.75
      expect(metrics.failureRate, closeTo(0.25, 0.01)); // 1/4 = 0.25
    });

    test('should calculate processing time statistics', () {
      metrics.jobCompleted('Job1', const Duration(milliseconds: 100));
      metrics.jobCompleted('Job2', const Duration(milliseconds: 200));
      metrics.jobCompleted('Job3', const Duration(milliseconds: 150));

      expect(metrics.minProcessingTime.inMilliseconds, equals(100));
      expect(metrics.maxProcessingTime.inMilliseconds, equals(200));
      expect(metrics.averageProcessingTime.inMilliseconds, equals(150));
    });

    test('should calculate percentiles', () {
      // Add 100 jobs with processing times from 1-100ms
      for (int i = 1; i <= 100; i++) {
        metrics.jobCompleted('Job$i', Duration(milliseconds: i));
      }

      expect(metrics.p50ProcessingTime.inMilliseconds, closeTo(50, 10));
      expect(metrics.p95ProcessingTime.inMilliseconds, closeTo(95, 10));
      expect(metrics.p99ProcessingTime.inMilliseconds, closeTo(99, 10));
    });

    test('should track queue depth', () {
      metrics.recordQueueDepth(0);
      metrics.recordQueueDepth(10);
      metrics.recordQueueDepth(20);
      metrics.recordQueueDepth(5);

      expect(metrics.currentQueueDepth, equals(5));
      expect(metrics.peakQueueDepth, equals(20));
      expect(metrics.averageQueueDepth, closeTo(8.75, 0.5));
    });

    test('should track worker utilization', () {
      metrics.recordWorkerUtilization(2, 4); // 50%
      metrics.recordWorkerUtilization(3, 4); // 75%
      metrics.recordWorkerUtilization(4, 4); // 100%

      expect(metrics.currentWorkerUtilization, closeTo(1.0, 0.01));
      expect(metrics.peakWorkerUtilization, closeTo(1.0, 0.01));
      expect(metrics.averageWorkerUtilization, closeTo(0.75, 0.01));
    });

    test('should track by priority', () {
      metrics.jobQueued('Job1', priority: JobPriority.critical);
      metrics.jobQueued('Job2', priority: JobPriority.high);
      metrics.jobQueued('Job3', priority: JobPriority.normal);

      metrics.jobCompleted(
        'Job1',
        const Duration(milliseconds: 10),
        priority: JobPriority.critical,
      );
      metrics.jobFailed('Job2', priority: JobPriority.high);

      expect(metrics.queuedByPriority[JobPriority.critical], equals(1));
      expect(metrics.queuedByPriority[JobPriority.high], equals(1));
      expect(metrics.queuedByPriority[JobPriority.normal], equals(1));
      expect(metrics.completedByPriority[JobPriority.critical], equals(1));
      expect(metrics.failedByPriority[JobPriority.high], equals(1));
    });

    test('should calculate throughput', () {
      metrics.startTime = DateTime.now().subtract(const Duration(seconds: 10));
      metrics.totalCompleted = 100;

      expect(metrics.throughput, closeTo(10.0, 1.0)); // 100 jobs / 10 seconds
    });

    test('should reset metrics', () {
      metrics.jobQueued('Job1');
      metrics.jobCompleted('Job1', const Duration(milliseconds: 100));
      metrics.recordQueueDepth(10);

      metrics.reset();

      expect(metrics.totalQueued, equals(0));
      expect(metrics.totalCompleted, equals(0));
      expect(metrics.currentQueueDepth, equals(0));
      expect(metrics.queuedByType.isEmpty, isTrue);
    });

    test('should export to JSON', () {
      metrics.jobQueued('TestJob');
      metrics.jobStarted();
      metrics.jobCompleted('TestJob', const Duration(milliseconds: 100));

      final json = metrics.toJson();

      expect(json['total_queued'], equals(1));
      expect(json['total_completed'], equals(1));
      expect(json['success_rate'], equals(1.0));
      expect(json.containsKey('average_processing_time_ms'), isTrue);
      expect(json.containsKey('p95_processing_time_ms'), isTrue);
    });

    test('should export to Prometheus format', () {
      metrics.totalQueued = 100;
      metrics.totalCompleted = 95;
      metrics.totalFailed = 5;

      final prometheus = metrics.toPrometheusFormat();

      expect(prometheus.contains('queue_total_queued 100'), isTrue);
      expect(prometheus.contains('queue_total_completed 95'), isTrue);
      expect(prometheus.contains('queue_total_failed 5'), isTrue);
      expect(prometheus.contains('# HELP'), isTrue);
      expect(prometheus.contains('# TYPE'), isTrue);
    });

    test('should handle edge cases for empty metrics', () {
      expect(metrics.successRate, equals(0.0));
      expect(metrics.averageProcessingTime, equals(Duration.zero));
      expect(metrics.throughput, equals(0.0));
      expect(metrics.currentQueueDepth, equals(0));
    });

    test('should limit history size', () {
      // Add more than max snapshots
      for (int i = 0; i < 1500; i++) {
        metrics.recordQueueDepth(i);
      }

      // Should not exceed max size
      final json = metrics.toJson();
      expect(json, isNotNull);
    });

    test('should calculate average processing time by type', () {
      metrics.jobCompleted('JobA', const Duration(milliseconds: 100));
      metrics.jobCompleted('JobA', const Duration(milliseconds: 200));
      metrics.jobCompleted('JobB', const Duration(milliseconds: 300));

      final avgA = metrics.averageProcessingTimeForType('JobA');
      final avgB = metrics.averageProcessingTimeForType('JobB');

      expect(avgA.inMilliseconds, equals(150)); // (100 + 200) / 2
      expect(avgB.inMilliseconds, equals(300));
    });
  });
}
