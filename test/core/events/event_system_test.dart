import 'package:test/test.dart';

// Import specific types from contracts to avoid ConfigInterface conflict
import '../../../lib/src/contracts/events/event_system_interface.dart';
import '../../../lib/src/core/events/event_system.dart';

class TestSubscriber {
  final String name;
  TestSubscriber(this.name);
}

void main() {
  group('EventSystem', () {
    late EventSystem events;

    setUp(() {
      events = EventSystem();
    });

    tearDown(() {
      events.clear();
    });

    group('on() - Basic listener registration', () {
      test('should register a listener for an event', () async {
        var called = false;
        events.on('test.event', (payload) async {
          called = true;
          expect(payload, equals('test data'));
        });

        await events.emit('test.event', 'test data');
        expect(called, isTrue);
      });

      test('should support multiple listeners for the same event', () async {
        var callCount = 0;
        events.on('test.event', (payload) async => callCount++);
        events.on('test.event', (payload) async => callCount++);

        await events.emit('test.event');
        expect(callCount, equals(2));
      });

      test('should handle listeners without payload', () async {
        var called = false;
        events.on('no.payload', (payload) async {
          called = true;
          expect(payload, isNull);
        });

        await events.emit('no.payload');
        expect(called, isTrue);
      });
    });

    group('on() - Priority execution', () {
      test('should execute listeners in priority order (high to low)', () async {
        final executionOrder = <String>[];

        events.on('priority.test', (payload) async {
          executionOrder.add('low');
        }, priority: EventPriority.low,);

        events.on('priority.test', (payload) async {
          executionOrder.add('normal');
        },);

        events.on('priority.test', (payload) async {
          executionOrder.add('high');
        }, priority: EventPriority.high,);

        events.on('priority.test', (payload) async {
          executionOrder.add('critical');
        }, priority: EventPriority.critical,);

        await events.emit('priority.test');

        expect(executionOrder, equals(['critical', 'high', 'normal', 'low']));
      });

      test('should maintain priority order with multiple listeners at same level', () async {
        final executionOrder = <int>[];

        events.on('same.priority', (payload) async => executionOrder.add(1));
        events.on('same.priority', (payload) async => executionOrder.add(2));
        events.on('same.priority', (payload) async => executionOrder.add(3));

        await events.emit('same.priority');

        expect(executionOrder, equals([1, 2, 3]));
      });
    });

    group('once()', () {
      test('should execute listener only once', () async {
        var callCount = 0;
        events.once('once.test', (payload) async => callCount++);

        await events.emit('once.test');
        await events.emit('once.test');
        await events.emit('once.test');

        expect(callCount, equals(1));
      });

      test('should remove listener after execution', () async {
        events.once('once.remove', (payload) async {});

        expect(events.hasListeners('once.remove'), isTrue);

        await events.emit('once.remove');

        expect(events.hasListeners('once.remove'), isFalse);
      });

      test('should support priority with once listeners', () async {
        final executionOrder = <String>[];

        events.once('once.priority', (payload) async => executionOrder.add('once-high'), priority: EventPriority.high);
        events.on('once.priority', (payload) async => executionOrder.add('normal'));

        await events.emit('once.priority');
        await events.emit('once.priority'); // Second emit should only trigger normal listener

        expect(executionOrder, equals(['once-high', 'normal', 'normal']));
      });
    });

    group('emit()', () {
      test('should return immediately when no listeners', () async {
        // Should not throw or hang
        await events.emit('nonexistent.event', 'data');
        expect(events.hasListeners('nonexistent.event'), isFalse);
      });

      test('should pass payload to all listeners', () async {
        final receivedPayloads = <dynamic>[];

        events.on('payload.test', (payload) async => receivedPayloads.add(payload));
        events.on('payload.test', (payload) async => receivedPayloads.add(payload));

        final testPayload = {'key': 'value', 'number': 42};
        await events.emit('payload.test', testPayload);

        expect(receivedPayloads.length, equals(2));
        expect(receivedPayloads[0], same(testPayload));
        expect(receivedPayloads[1], same(testPayload));
      });

      test('should handle async listeners', () async {
        var completed = false;

        events.on('async.test', (payload) async {
          await Future.delayed(const Duration(milliseconds: 10));
          completed = true;
        });

        await events.emit('async.test');
        expect(completed, isTrue);
      });

      test('should handle exceptions in listeners gracefully', () async {
        var goodListenerCalled = false;

        events.on('exception.test', (payload) async {
          throw Exception('Test exception');
        });

        events.on('exception.test', (payload) async {
          goodListenerCalled = true;
        });

        // Should not throw, should continue executing other listeners
        await events.emit('exception.test');
        expect(goodListenerCalled, isTrue);
      });
    });

    group('emit() - Queue option', () {
      test('should execute listeners asynchronously when queued', () async {
        final executionOrder = <String>[];

        events.on('queue.test', (payload) async {
          executionOrder.add('sync-start');
          await Future.delayed(const Duration(milliseconds: 5));
          executionOrder.add('sync-end');
        },);

        events.on('queue.test', (payload) async {
          executionOrder.add('queued-start');
          await Future.delayed(const Duration(milliseconds: 1));
          executionOrder.add('queued-end');
        }, priority: EventPriority.low,);

        await events.emit('queue.test', null, true); // queue = true

        // With queue=true, listeners should run in parallel
        expect(executionOrder, contains('sync-start'));
        expect(executionOrder, contains('queued-start'));
      });

      test('should execute listeners synchronously when not queued', () async {
        final executionOrder = <String>[];

        events.on('sync.test', (payload) async {
          executionOrder.add('first');
          await Future.delayed(const Duration(milliseconds: 5));
          executionOrder.add('first-done');
        });

        events.on('sync.test', (payload) async {
          executionOrder.add('second');
          await Future.delayed(const Duration(milliseconds: 1));
          executionOrder.add('second-done');
        });

        await events.emit('sync.test'); // queue = false

        // Should execute in order
        expect(executionOrder, equals(['first', 'first-done', 'second', 'second-done']));
      });
    });

    group('off()', () {
      test('should remove specific listener', () async {
        var callCount = 0;

        final listener1 = (payload) async => callCount++;
        final listener2 = (payload) async => callCount += 10;

        events.on('remove.test', listener1);
        events.on('remove.test', listener2);

        await events.emit('remove.test');
        expect(callCount, equals(11)); // 1 + 10

        events.off('remove.test', listener1);
        await events.emit('remove.test');
        expect(callCount, equals(21)); // 11 + 10

        events.off('remove.test', listener2);
        await events.emit('remove.test');
        expect(callCount, equals(21)); // No change
      });

      test('should remove event when last listener is removed', () {
        final listener = (payload) async {};
        events.on('cleanup.test', listener);

        expect(events.hasListeners('cleanup.test'), isTrue);

        events.off('cleanup.test', listener);

        expect(events.hasListeners('cleanup.test'), isFalse);
      });
    });

    group('offEvent()', () {
      test('should remove all listeners for an event', () async {
        var callCount = 0;

        events.on('clear.test', (payload) async => callCount++);
        events.on('clear.test', (payload) async => callCount++);

        await events.emit('clear.test');
        expect(callCount, equals(2));

        events.offEvent('clear.test');

        await events.emit('clear.test');
        expect(callCount, equals(2)); // No additional calls
        expect(events.hasListeners('clear.test'), isFalse);
      });

      test('should remove event from groups when clearing', () {
        events.addToGroup('test.group', 'clear.group.test');
        events.on('clear.group.test', (payload) async {});

        expect(events.eventGroups['test.group'], contains('clear.group.test'));

        events.offEvent('clear.group.test');

        expect(events.eventGroups.containsKey('test.group'), isFalse);
      });
    });

    group('Subscriber management', () {
      test('should track listeners by subscriber', () {
        final subscriber = TestSubscriber('test');

        events.on('subscriber.test', (payload) async {}, subscriber: subscriber);

        expect(events.subscriberEvents[subscriber], contains('subscriber.test'));
      });

      test('should remove all listeners for a subscriber', () async {
        final subscriber = TestSubscriber('test');
        var callCount = 0;

        events.on('sub1', (payload) async => callCount++, subscriber: subscriber);
        events.on('sub2', (payload) async => callCount++, subscriber: subscriber);

        await events.emit('sub1');
        await events.emit('sub2');
        expect(callCount, equals(2));

        events.offSubscriber(subscriber);

        await events.emit('sub1');
        await events.emit('sub2');
        expect(callCount, equals(2)); // No additional calls
      });

      test('should handle multiple subscribers independently', () {
        final sub1 = TestSubscriber('sub1');
        final sub2 = TestSubscriber('sub2');

        events.on('shared.event', (payload) async {}, subscriber: sub1);
        events.on('shared.event', (payload) async {}, subscriber: sub2);

        expect(events.subscriberEvents[sub1], contains('shared.event'));
        expect(events.subscriberEvents[sub2], contains('shared.event'));

        events.offSubscriber(sub1);

        expect(events.subscriberEvents.containsKey(sub1), isFalse);
        expect(events.subscriberEvents[sub2], contains('shared.event'));
      });
    });

    group('Event groups', () {
      test('should add events to groups', () {
        events.addToGroup('user.events', 'user.created');
        events.addToGroup('user.events', 'user.updated');

        expect(events.eventGroups['user.events'], contains('user.created'));
        expect(events.eventGroups['user.events'], contains('user.updated'));
      });

      test('should emit all events in a group', () async {
        var callCount = 0;

        events.on('group1', (payload) async => callCount++);
        events.on('group2', (payload) async => callCount++);

        events.addToGroup('test.group', 'group1');
        events.addToGroup('test.group', 'group2');

        await events.emitGroup('test.group');

        expect(callCount, equals(2));
      });

      test('should handle empty groups gracefully', () async {
        await events.emitGroup('nonexistent.group');
        // Should not throw
      });

      test('should remove events from groups', () {
        events.addToGroup('test.group', 'event1');
        events.addToGroup('test.group', 'event2');

        expect(events.eventGroups['test.group'], hasLength(2));

        events.removeFromGroup('test.group', 'event1');

        expect(events.eventGroups['test.group'], hasLength(1));
        expect(events.eventGroups['test.group'], contains('event2'));
      });

      test('should remove empty groups automatically', () {
        events.addToGroup('empty.group', 'only.event');
        expect(events.eventGroups.containsKey('empty.group'), isTrue);

        events.removeFromGroup('empty.group', 'only.event');

        expect(events.eventGroups.containsKey('empty.group'), isFalse);
      });
    });

    group('Query methods', () {
      test('hasListeners() should return correct status', () {
        expect(events.hasListeners('empty.event'), isFalse);

        events.on('has.listeners', (payload) async {});
        expect(events.hasListeners('has.listeners'), isTrue);

        events.offEvent('has.listeners');
        expect(events.hasListeners('has.listeners'), isFalse);
      });

      test('listenerCount() should return correct count', () {
        expect(events.listenerCount('no.listeners'), equals(0));

        events.on('count.test', (payload) async {});
        events.on('count.test', (payload) async {});
        expect(events.listenerCount('count.test'), equals(2));

        events.offEvent('count.test');
        expect(events.listenerCount('count.test'), equals(0));
      });
    });

    group('clear()', () {
      test('should remove all listeners and groups', () {
        events.on('clear.test', (payload) async {});
        events.addToGroup('clear.group', 'clear.test');
        events.on('subscriber.test', (payload) async {}, subscriber: TestSubscriber('test'));

        expect(events.hasListeners('clear.test'), isTrue);
        expect(events.eventGroups.isNotEmpty, isTrue);
        expect(events.subscriberEvents.isNotEmpty, isTrue);

        events.clear();

        expect(events.hasListeners('clear.test'), isFalse);
        expect(events.eventGroups.isEmpty, isTrue);
        expect(events.subscriberEvents.isEmpty, isTrue);
      });
    });

    group('Integration tests', () {
      test('should handle complex event flow with priorities and groups', () async {
        final executionLog = <String>[];

        // Set up listeners with different priorities
        events.on('complex.test', (payload) async => executionLog.add('normal-1'));
        events.on('complex.test', (payload) async => executionLog.add('high-1'), priority: EventPriority.high);
        events.once('complex.test', (payload) async => executionLog.add('once-critical'), priority: EventPriority.critical);

        // Add to group
        events.addToGroup('complex.group', 'complex.test');
        events.addToGroup('complex.group', 'complex.test'); // Duplicate should be handled

        // Emit through group
        await events.emitGroup('complex.group');

        expect(executionLog, equals(['once-critical', 'high-1', 'normal-1']));

        // Emit again - once listener should be gone
        executionLog.clear();
        await events.emit('complex.test');

        expect(executionLog, equals(['high-1', 'normal-1']));
      });

      test('should handle subscriber lifecycle', () async {
        final component = TestSubscriber('component');
        var callCount = 0;

        // Component registers multiple events
        events.on('component.init', (payload) async => callCount++, subscriber: component);
        events.on('component.update', (payload) async => callCount++, subscriber: component);
        events.on('component.destroy', (payload) async => callCount++, subscriber: component);

        // Events fire
        await events.emit('component.init');
        await events.emit('component.update');
        expect(callCount, equals(2));

        // Component is destroyed - all its listeners should be removed
        events.offSubscriber(component);

        await events.emit('component.destroy');
        expect(callCount, equals(2)); // No additional calls
      });
    });
  });
}
