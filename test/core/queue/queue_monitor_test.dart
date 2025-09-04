import 'package:test/test.dart';

import '../../../lib/src/contracts/queue/queue_job.dart';
import '../../../lib/src/core/queue/queue_monitor.dart';

// Test job implementation
class TestQueueJob extends QueueJob {
  final String name;

  TestQueueJob(this.name);

  @override
  Future<void> handle() async {
    // Test implementation
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};

  @override
  TestQueueJob fromJson(Map<String, dynamic> json) => TestQueueJob(json['name']);
}

void main() {
  group('BasicQueueMonitor', () {
    late BasicQueueMonitor monitor;
    late TestQueueJob job1;
    late TestQueueJob job2;

    setUp(() {
      monitor = BasicQueueMonitor();
      job1 = TestQueueJob('job1');
      job2 = TestQueueJob('job2');
    });

    test('should start with zero metrics', () {
      final metrics = monitor.getMetrics();

      expect(metrics.totalQueued, equals(0));
      expect(metrics.totalStarted, equals(0));
      expect(metrics.totalCompleted, equals(0));
      expect(metrics.totalFailed, equals(0));
      expect(metrics.currentlyProcessing, equals(0));
    });

    test('should record job queued', () {
      monitor.jobQueued(job1);

      final metrics = monitor.getMetrics();
      expect(metrics.totalQueued, equals(1));
      expect(metrics.queuedByType['TestQueueJob'], equals(1));
    });

    test('should record job started', () {
      monitor.jobStarted(job1);

      final metrics = monitor.getMetrics();
      expect(metrics.totalStarted, equals(1));
      expect(metrics.currentlyProcessing, equals(1));
    });

    test('should record job completed', () {
      monitor.jobStarted(job1);
      monitor.jobCompleted(job1, const Duration(seconds: 2));

      final metrics = monitor.getMetrics();
      expect(metrics.totalCompleted, equals(1));
      expect(metrics.currentlyProcessing, equals(0));
      expect(metrics.totalProcessingTime, equals(const Duration(seconds: 2)));
      expect(metrics.completedByType['TestQueueJob'], equals(1));
    });

    test('should record job failed', () {
      monitor.jobStarted(job1);
      monitor.jobFailed(job1, 'Test error', const Duration(seconds: 1));

      final metrics = monitor.getMetrics();
      expect(metrics.totalFailed, equals(1));
      expect(metrics.currentlyProcessing, equals(0));
      expect(metrics.totalProcessingTime, equals(const Duration(seconds: 1)));
      expect(metrics.failedByType['TestQueueJob'], equals(1));
    });

    test('should record job retried', () {
      monitor.jobRetried(job1, 1);

      final metrics = monitor.getMetrics();
      expect(metrics.totalRetried, equals(1));
      expect(metrics.retriedByType['TestQueueJob'], equals(1));
    });

    test('should calculate success rate', () {
      monitor.jobCompleted(job1, Duration.zero);
      monitor.jobFailed(job2, 'error', Duration.zero);

      final metrics = monitor.getMetrics();
      expect(metrics.successRate, equals(0.5));
    });

    test('should calculate failure rate', () {
      monitor.jobCompleted(job1, Duration.zero);
      monitor.jobFailed(job2, 'error', Duration.zero);

      final metrics = monitor.getMetrics();
      expect(metrics.failureRate, equals(0.5));
    });

    test('should calculate average processing time', () {
      monitor.jobCompleted(job1, const Duration(seconds: 1));
      monitor.jobCompleted(job2, const Duration(seconds: 3));

      final metrics = monitor.getMetrics();
      expect(metrics.averageProcessingTime, equals(const Duration(seconds: 2)));
    });

    test('should reset metrics', () {
      monitor.jobQueued(job1);
      monitor.jobStarted(job1);
      monitor.jobCompleted(job1, const Duration(seconds: 1));

      monitor.reset();

      final metrics = monitor.getMetrics();
      expect(metrics.totalQueued, equals(0));
      expect(metrics.totalCompleted, equals(0));
      expect(metrics.queuedByType, isEmpty);
    });
  });

  group('QueueMetrics', () {
    test('should convert to JSON', () {
      final metrics = QueueMetrics();
      metrics.totalQueued = 5;
      metrics.totalCompleted = 3;
      metrics.totalFailed = 2;

      final json = metrics.toJson();

      expect(json['total_queued'], equals(5));
      expect(json['total_completed'], equals(3));
      expect(json['total_failed'], equals(2));
      expect(json['success_rate'], equals(0.6));
      expect(json['failure_rate'], equals(0.4));
    });
  });
}
