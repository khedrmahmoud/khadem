import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/config/config_contract.dart';
import '../../../lib/src/contracts/queue/queue_driver.dart';
import '../../../lib/src/contracts/queue/queue_job.dart';
import '../../../lib/src/core/queue/queue_manager.dart';

// Mock classes for testing
class MockConfig extends Mock implements ConfigInterface {}

class ManualMockQueueDriver implements QueueDriver {
  Future<void> Function(QueueJob job, Duration? delay)? pushCallback;
  Future<void> Function()? processCallback;

  @override
  Future<void> push(QueueJob job, {Duration? delay}) {
    if (pushCallback != null) {
      return pushCallback!(job, delay);
    }
    return Future.value();
  }

  @override
  Future<void> process() {
    if (processCallback != null) {
      return processCallback!();
    }
    return Future.value();
  }
}

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
  group('QueueManager', () {
    test('should initialize with config', () {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      expect(manager, isNotNull);
    });

    test('should initialize driver', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      await manager.init();

      expect(manager.driver, isNotNull);
      expect(manager.defaultDriverName, isNotNull);
    });

    test('should dispatch job successfully', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');
      final testJob = TestQueueJob('test');

      mockDriver.pushCallback = (job, delay) => Future.value();

      await expectLater(manager.dispatch(testJob), completes);
    });

    test('should dispatch job with delay', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');
      final testJob = TestQueueJob('test');
      const delay = Duration(seconds: 30);

      mockDriver.pushCallback = (job, delay) => Future.value();

      await expectLater(manager.dispatch(testJob, delay: delay), completes);
    });

    test('should handle dispatch errors', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');
      final testJob = TestQueueJob('test');

      mockDriver.pushCallback = (job, delay) => Future.error(Exception('Dispatch failed'));

      expect(() => manager.dispatch(testJob), throwsException);
    });

    test('should process jobs', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      mockDriver.processCallback = () => Future.value();

      await expectLater(manager.process(), completes);
    });

  

    test('should start worker with default config', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      mockDriver.processCallback = () => Future.value();

      await expectLater(manager.startWorker(maxJobs: 1), completes);
    });

    test('should start worker with custom config', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      mockDriver.processCallback = () => Future.value();

      await expectLater(manager.startWorker(
        maxJobs: 5,
        delay: const Duration(seconds: 2),
        timeout: const Duration(minutes: 1),
      ), completes,);
    });

    test('should get metrics', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      await manager.init();

      final metrics = manager.getMetrics();
      expect(metrics, isA<Map<String, dynamic>>());
    });

    test('should reset metrics', () async {
      final config = MockConfig();
      final mockDriver = ManualMockQueueDriver();
      final manager = QueueManager(config, driver: mockDriver, driverName: 'mock');

      await manager.init();

      expect(() => manager.resetMetrics(), returnsNormally);
    });

  

    test('should provide access to registry', () {
      final registry = QueueManager.registry;
      expect(registry, isNotNull);
    });
  });
}
