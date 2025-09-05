import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/config/config_contract.dart';
import '../../../lib/src/contracts/queue/queue_driver.dart';
import '../../../lib/src/contracts/queue/queue_job.dart';
import '../../../lib/src/core/queue/queue_driver_registry.dart';
import '../../../lib/src/core/queue/queue_factory.dart';

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
}

void main() {
  group('QueueFactory', () {
 

 

    test('should provide access to registry', () {
      final registry = QueueFactory.instance.registry;

      expect(registry, isA<QueueDriverRegistry>());
      expect(registry.hasDriver('sync'), isTrue);
    });

  
  });
}
