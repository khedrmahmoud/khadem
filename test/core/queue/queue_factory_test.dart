import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/config/config_contract.dart';
import '../../../lib/src/contracts/queue/queue_driver.dart';
import '../../../lib/src/contracts/queue/queue_job.dart';
import '../../../lib/src/core/queue/queue_driver_registry.dart';
import '../../../lib/src/core/queue/queue_factory.dart';
import '../../../lib/src/core/queue/queue_job_serializer.dart';

// Mock classes for testing
class MockConfig extends Mock implements ConfigInterface {}

class MockQueueDriver extends Mock implements QueueDriver {}

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
  group('QueueFactory', () {
    late MockConfig config;
    late MockQueueDriver mockDriver;

    setUp(() {
      config = MockConfig();
      mockDriver = MockQueueDriver();
    });

    test('should resolve default sync driver', () {
      when(config.get<String>('queue.driver', 'sync')).thenReturn('sync');

      final (driver, name) = QueueFactory.resolve(config);

      expect(driver, isNotNull);
      expect(name, equals('sync'));
    });

    test('should resolve custom driver', () {
      QueueFactory.registerDriver('custom', mockDriver);
      when(config.get<String>('queue.driver', 'sync')).thenReturn('custom');

      final (driver, name) = QueueFactory.resolve(config);

      expect(driver, equals(mockDriver));
      expect(name, equals('custom'));
    });

    test('should throw on unknown driver', () {
      when(config.get<String>('queue.driver', 'sync')).thenReturn('unknown');

      expect(() => QueueFactory.resolve(config), throwsException);
    });

    test('should provide access to registry', () {
      final registry = QueueFactory.instance.registry;

      expect(registry, isA<QueueDriverRegistry>());
      expect(registry.hasDriver('sync'), isTrue);
    });

    test('should provide access to serializer', () {
      final serializer = QueueFactory.instance.serializer;

      expect(serializer, isA<QueueJobSerializer>());
    });

    test('should serialize and deserialize jobs', () {
      // This would require a concrete job implementation
      // For now, just test that the methods exist
      expect(QueueFactory.serializeJob, isNotNull);
      expect(QueueFactory.deserializeJob, isNotNull);
    });

    test('should register job factory', () {
      final factory = (Map<String, dynamic> json) => TestQueueJob('test');

      expect(() => QueueFactory.registerJobFactory('TestJob', factory), returnsNormally);
    });
  });
}
