import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/config/config_contract.dart';
import '../../../lib/src/contracts/queue/queue_driver.dart';
import '../../../lib/src/contracts/queue/queue_job.dart';
import '../../../lib/src/core/queue/queue_manager.dart';

// Mock classes for testing
class MockConfig extends Mock implements ConfigInterface {}

class MockQueueDriver extends Mock implements QueueDriver {}

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
    late MockConfig config;
    late QueueManager manager;
    late TestQueueJob testJob;

    setUp(() {
      config = MockConfig();
      manager = QueueManager(config);
      testJob = TestQueueJob('test');

      // Mock the factory resolution
      when(config.get<String>('queue.driver', 'sync')).thenReturn('sync');
    });

    test('should initialize with config', () {
      expect(manager, isNotNull);
    });

    test('should initialize driver', () async {
      await manager.init();

      expect(manager.driver, isNotNull);
      expect(manager.defaultDriverName, isNotNull);
    });

    test('should dispatch job successfully', () async {
      await manager.init();
      when(manager.driver.push(testJob, delay: null)).thenAnswer((_) async {});

      await expectLater(manager.dispatch(testJob), completes);
      verify(manager.driver.push(testJob, delay: null)).called(1);
    });

    test('should dispatch job with delay', () async {
      await manager.init();
      final delay = Duration(seconds: 30);
      when(manager.driver.push(testJob, delay: delay)).thenAnswer((_) async {});

      await expectLater(manager.dispatch(testJob, delay: delay), completes);
      verify(manager.driver.push(testJob, delay: delay)).called(1);
    });

    test('should handle dispatch errors', () async {
      await manager.init();
      when(manager.driver.push(testJob, delay: null))
          .thenThrow(Exception('Dispatch failed'));

      expect(() => manager.dispatch(testJob), throwsException);
    });

    test('should process jobs', () async {
      await manager.init();
      when(manager.driver.process()).thenAnswer((_) async {});

      await expectLater(manager.process(), completes);
      verify(manager.driver.process()).called(1);
    });

    test('should handle processing errors gracefully', () async {
      await manager.init();
      when(manager.driver.process()).thenThrow(Exception('Processing failed'));

      // Should not throw exception
      await expectLater(manager.process(), completes);
    });

    test('should start worker with default config', () async {
      await manager.init();
      when(manager.driver.process()).thenAnswer((_) async {});

      await expectLater(manager.startWorker(maxJobs: 1), completes);
    });

    test('should start worker with custom config', () async {
      await manager.init();
      when(manager.driver.process()).thenAnswer((_) async {});

      await expectLater(manager.startWorker(
        maxJobs: 5,
        delay: Duration(seconds: 2),
        timeout: Duration(minutes: 1),
        runInBackground: false,
      ), completes);
    });

    test('should get metrics', () async {
      await manager.init();

      final metrics = manager.getMetrics();
      expect(metrics, isA<Map<String, dynamic>>());
    });

    test('should reset metrics', () async {
      await manager.init();

      expect(() => manager.resetMetrics(), returnsNormally);
    });

    test('should provide access to serializer', () {
      final serializer = QueueManager.serializer;
      expect(serializer, isNotNull);
    });

    test('should provide access to registry', () {
      final registry = QueueManager.registry;
      expect(registry, isNotNull);
    });
  });
}
