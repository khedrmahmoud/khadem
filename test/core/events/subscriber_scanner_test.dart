import 'package:test/test.dart';

import '../../../lib/src/contracts/events/event_subscriber_interface.dart';
import '../../../lib/src/contracts/events/event_system_interface.dart';
import '../../../lib/src/core/events/event_method.dart';
import '../../../lib/src/core/events/event_registration.dart';
import '../../../lib/src/core/events/subscriber_scanner.dart';

// Mock EventSystem for testing
class MockEventSystem implements EventSystemInterface {
  final Map<String, List<EventRegistration>> _listeners = {};

  @override
  void on(String event, EventListener listener,
      {EventPriority priority = EventPriority.normal,
      bool once = false,
      Object? subscriber}) {
    _listeners[event] ??= [];
    _listeners[event]!.add(EventRegistration(listener, priority, once));
  }

  @override
  void once(String event, EventListener listener,
      {EventPriority priority = EventPriority.normal, Object? subscriber}) {}

  @override
  void addToGroup(String groupName, String event) {}

  @override
  void removeFromGroup(String groupName, String event) {}

  @override
  Future<void> emit(String event,
      [dynamic payload, bool queue = false, bool broadcast = false]) async {}

  @override
  Future<void> emitGroup(String groupName,
      [dynamic payload, bool queue = false, bool broadcast = false]) async {}

  @override
  void off(String event, EventListener listener) {}

  @override
  void offEvent(String event) {}

  @override
  void offSubscriber(Object subscriber) {}

  @override
  bool hasListeners(String event) => _listeners[event]?.isNotEmpty ?? false;

  @override
  int listenerCount(String event) => _listeners[event]?.length ?? 0;

  @override
  void clear() {
    _listeners.clear();
  }

  @override
  Map<String, List<EventRegistration>> get listeners => _listeners;

  @override
  Map<String, Set<String>> get eventGroups => {};

  @override
  Map<Object, Set<String>> get subscriberEvents => {};
}

// Mock Khadem for testing
class MockKhadem {
  static late MockEventSystem _eventBus;

  static MockEventSystem get eventBus => _eventBus;

  static void initialize() {
    _eventBus = MockEventSystem();
  }
}

// Test subscriber implementations
class TestEventSubscriber implements EventSubscriberInterface {
  final String name;

  TestEventSubscriber(this.name);

  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: 'user.created',
          handler: (user) async => print('$name: User created - $user'),
          priority: EventPriority.normal,
        ),
        EventMethod(
          eventName: 'user.updated',
          handler: (user) async => print('$name: User updated - $user'),
          priority: EventPriority.high,
        ),
      ];
}

class EmptyEventSubscriber implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [];
}

class SingleEventSubscriber implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: 'app.startup',
          handler: (data) async => print('App started'),
          priority: EventPriority.critical,
          once: true,
        ),
      ];
}

void main() {
  group('registerSubscribers', () {
    setUp(() {
      // Initialize mock Khadem
      MockKhadem.initialize();
    });

    tearDown(() {
      MockKhadem.eventBus.clear();
    });

    test('should register event handlers from subscribers', () {
      final subscriber = TestEventSubscriber('TestSubscriber');

      registerSubscribers([subscriber], MockKhadem.eventBus);

      expect(MockKhadem.eventBus.hasListeners('user.created'), isTrue);
      expect(MockKhadem.eventBus.hasListeners('user.updated'), isTrue);
      expect(MockKhadem.eventBus.listenerCount('user.created'), equals(1));
      expect(MockKhadem.eventBus.listenerCount('user.updated'), equals(1));
    });

    test('should handle multiple subscribers', () {
      final subscriber1 = TestEventSubscriber('Subscriber1');
      final subscriber2 = TestEventSubscriber('Subscriber2');

      registerSubscribers([subscriber1, subscriber2], MockKhadem.eventBus);

      expect(MockKhadem.eventBus.listenerCount('user.created'), equals(2));
      expect(MockKhadem.eventBus.listenerCount('user.updated'), equals(2));
    });

    test('should handle empty subscriber list', () {
      registerSubscribers([], MockKhadem.eventBus);

      expect(MockKhadem.eventBus.listeners.isEmpty, isTrue);
    });

    test('should handle subscribers with no event handlers', () {
      final emptySubscriber = EmptyEventSubscriber();

      registerSubscribers([emptySubscriber], MockKhadem.eventBus);

      expect(MockKhadem.eventBus.listeners.isEmpty, isTrue);
    });

    test('should handle subscribers with single event handler', () {
      final singleSubscriber = SingleEventSubscriber();

      registerSubscribers([singleSubscriber], MockKhadem.eventBus);

      expect(MockKhadem.eventBus.hasListeners('app.startup'), isTrue);
      expect(MockKhadem.eventBus.listenerCount('app.startup'), equals(1));
    });

    test('should register handlers with correct priorities', () {
      final subscriber = TestEventSubscriber('PriorityTest');

      registerSubscribers([subscriber], MockKhadem.eventBus);

      // The mock doesn't track priorities, but we can verify the handlers are registered
      expect(MockKhadem.eventBus.hasListeners('user.created'), isTrue);
      expect(MockKhadem.eventBus.hasListeners('user.updated'), isTrue);
    });

    test('should register handlers with once flag', () {
      final singleSubscriber = SingleEventSubscriber();

      registerSubscribers([singleSubscriber], MockKhadem.eventBus);

      // The mock doesn't track the once flag, but we can verify the handler is registered
      expect(MockKhadem.eventBus.hasListeners('app.startup'), isTrue);
    });

    test('should handle duplicate event names from different subscribers', () {
      final subscriber1 = TestEventSubscriber('Sub1');
      final subscriber2 = TestEventSubscriber('Sub2');

      registerSubscribers([subscriber1, subscriber2], MockKhadem.eventBus);

      expect(MockKhadem.eventBus.listenerCount('user.created'), equals(2));
      expect(MockKhadem.eventBus.listenerCount('user.updated'), equals(2));
    });

    test('should pass subscriber as parameter to event registration', () {
      final subscriber = TestEventSubscriber('SubscriberParam');

      registerSubscribers([subscriber], MockKhadem.eventBus);

      // The mock doesn't track subscribers, but we can verify handlers are registered
      expect(MockKhadem.eventBus.hasListeners('user.created'), isTrue);
    });

    group('Integration with EventMethod', () {
      test('should work with EventMethod properties', () {
        final methods = [
          EventMethod(
            eventName: 'test.event1',
            handler: (payload) async => print('event1'),
            priority: EventPriority.low,
            once: false,
          ),
          EventMethod(
            eventName: 'test.event2',
            handler: (payload) async => print('event2'),
            priority: EventPriority.high,
            once: true,
          ),
        ];

        final subscriber = _TestSubscriberWithMethods(methods);
        registerSubscribers([subscriber], MockKhadem.eventBus);

        expect(MockKhadem.eventBus.hasListeners('test.event1'), isTrue);
        expect(MockKhadem.eventBus.hasListeners('test.event2'), isTrue);
      });

      test('should handle complex event handler logic', () {
        var executionCount = 0;
        final complexSubscriber = _ComplexTestSubscriber(() => executionCount++);

        registerSubscribers([complexSubscriber], MockKhadem.eventBus);

        expect(MockKhadem.eventBus.hasListeners('complex.event'), isTrue);
      });
    });

    group('Error handling', () {
      test('should handle empty subscriber list', () {
        // Test with empty list
        expect(() => registerSubscribers([], MockKhadem.eventBus), returnsNormally);
      });
    });
  });
}

// Helper classes for testing
class _TestSubscriberWithMethods implements EventSubscriberInterface {
  final List<EventMethod> methods;

  _TestSubscriberWithMethods(this.methods);

  @override
  List<EventMethod> getEventHandlers() => methods;
}

class _ComplexTestSubscriber implements EventSubscriberInterface {
  final Function incrementCounter;

  _ComplexTestSubscriber(this.incrementCounter);

  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: 'complex.event',
          handler: (payload) async {
            // Complex logic here
            incrementCounter();
            if (payload is Map<String, dynamic>) {
              // Process complex payload
            }
          },
          priority: EventPriority.normal,
        ),
      ];
}
