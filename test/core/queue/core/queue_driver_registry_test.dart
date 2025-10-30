import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/core/queue/registry/index.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Mock classes for testing
class MockQueueDriver extends Mock implements QueueDriver {}

void main() {
  group('QueueDriverRegistry', () {
    late QueueDriverRegistry registry;
    late MockQueueDriver driver1;
    late MockQueueDriver driver2;

    setUp(() {
      registry = QueueDriverRegistry();
      driver1 = MockQueueDriver();
      driver2 = MockQueueDriver();
    });

    test('should start with no drivers', () {
      expect(registry.getDriverNames(), isEmpty);
    });

    test('should register and retrieve driver', () {
      registry.registerDriver('test', driver1);

      expect(registry.getDriver('test'), equals(driver1));
      expect(registry.hasDriver('test'), isTrue);
      expect(registry.getDriverNames(), contains('test'));
    });

    test('should return null for unregistered driver', () {
      expect(registry.getDriver('nonexistent'), isNull);
      expect(registry.hasDriver('nonexistent'), isFalse);
    });

    test('should register multiple drivers', () {
      registry.registerDriver('driver1', driver1);
      registry.registerDriver('driver2', driver2);

      expect(registry.getDriver('driver1'), equals(driver1));
      expect(registry.getDriver('driver2'), equals(driver2));
      expect(registry.getDriverNames(), hasLength(2));
      expect(registry.getDriverNames(), containsAll(['driver1', 'driver2']));
    });

    test('should unregister driver', () {
      // Register a default driver first
      registry.registerDriver('default', driver2);
      registry.registerDriver('test', driver1);
      expect(registry.hasDriver('test'), isTrue);

      registry.unregister('test');
      expect(registry.hasDriver('test'), isFalse);
      expect(registry.getDriver('test'), isNull);
    });

    test('should clear all drivers', () {
      registry.registerDriver('driver1', driver1);
      registry.registerDriver('driver2', driver2);
      expect(registry.getDriverNames(), hasLength(2));

      registry.clear();
      expect(registry.getDriverNames(), isEmpty);
    });
  });
}
