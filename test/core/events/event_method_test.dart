import 'package:test/test.dart';

import '../../../lib/src/contracts/events/event_system_interface.dart';
import '../../../lib/src/core/events/event_method.dart';

void main() {
  group('EventMethod', () {
    late EventMethod method;

    setUp(() {
      method = EventMethod(
        eventName: 'test.event',
        handler: (payload) async => print('handled'),
      );
    });

    group('Constructor', () {
      test('should create method with required parameters', () {
        final handler = (payload) async => 'result';
        const eventName = 'required.event';

        final method = EventMethod(
          eventName: eventName,
          handler: handler,
        );

        expect(method.eventName, equals(eventName));
        expect(method.handler, same(handler));
        expect(method.priority, equals(EventPriority.normal));
        expect(method.once, isFalse);
      });

      test('should allow custom priority', () {
        final method = EventMethod(
          eventName: 'custom.priority',
          handler: (payload) async {},
          priority: EventPriority.high,
        );

        expect(method.priority, equals(EventPriority.high));
      });

      test('should allow once flag', () {
        final method = EventMethod(
          eventName: 'once.event',
          handler: (payload) async {},
          once: true,
        );

        expect(method.once, isTrue);
      });

      test('should handle all priority levels', () {
        final priorities = [
          EventPriority.low,
          EventPriority.normal,
          EventPriority.high,
          EventPriority.critical,
        ];

        for (final priority in priorities) {
          final method = EventMethod(
            eventName: 'priority.test',
            handler: (payload) async {},
            priority: priority,
          );

          expect(method.priority, equals(priority));
        }
      });
    });

    group('Properties', () {
      test('should maintain eventName', () {
        expect(method.eventName, equals('test.event'));

        final customMethod = EventMethod(
          eventName: 'custom.event.name',
          handler: (payload) async {},
        );

        expect(customMethod.eventName, equals('custom.event.name'));
      });

      test('should maintain handler reference', () {
        final originalHandler = method.handler;
        expect(originalHandler, isNotNull);

        // Handler should remain the same reference
        expect(method.handler, same(originalHandler));
      });

      test('should maintain priority', () {
        expect(method.priority, equals(EventPriority.normal));

        final highPriorityMethod = EventMethod(
          eventName: 'high.priority',
          handler: (payload) async {},
          priority: EventPriority.high,
        );

        expect(highPriorityMethod.priority, equals(EventPriority.high));
      });

      test('should maintain once flag', () {
        expect(method.once, isFalse);

        final onceMethod = EventMethod(
          eventName: 'once.method',
          handler: (payload) async {},
          once: true,
        );

        expect(onceMethod.once, isTrue);
      });
    });

    group('Handler execution', () {
      test('should execute handler with payload', () async {
        dynamic receivedPayload;
        final method = EventMethod(
          eventName: 'payload.test',
          handler: (payload) async {
            receivedPayload = payload;
          },
        );

        await method.handler('test payload');
        expect(receivedPayload, equals('test payload'));
      });

      test('should handle null payload', () async {
        dynamic receivedPayload = 'not null';
        final method = EventMethod(
          eventName: 'null.payload',
          handler: (payload) async {
            receivedPayload = payload;
          },
        );

        await method.handler(null);
        expect(receivedPayload, isNull);
      });

      test('should handle complex payloads', () async {
        final complexPayload = {
          'user': {'id': 1, 'name': 'Alice'},
          'action': 'login',
          'timestamp': DateTime.now(),
        };

        Map<String, dynamic>? receivedPayload;
        final method = EventMethod(
          eventName: 'complex.payload',
          handler: (payload) async {
            receivedPayload = payload as Map<String, dynamic>;
          },
        );

        await method.handler(complexPayload);
        expect(receivedPayload, same(complexPayload));
        expect(receivedPayload?['user']['name'], equals('Alice'));
      });

      test('should handle async operations in handler', () async {
        var completed = false;
        final method = EventMethod(
          eventName: 'async.handler',
          handler: (payload) async {
            await Future.delayed(const Duration(milliseconds: 10));
            completed = true;
          },
        );

        await method.handler('test');
        expect(completed, isTrue);
      });

      test('should handle exceptions in handler', () async {
        final method = EventMethod(
          eventName: 'exception.handler',
          handler: (payload) async {
            throw Exception('Test exception');
          },
        );

        expect(() async => method.handler('test'), throwsA(isA<Exception>()));
      });
    });

    group('Integration with EventSubscriber', () {
      test('should work as part of subscriber pattern', () {
        final methods = [
          EventMethod(
            eventName: 'user.created',
            handler: (user) async => print('User created: $user'),
          ),
          EventMethod(
            eventName: 'user.updated',
            handler: (user) async => print('User updated: $user'),
            priority: EventPriority.high,
          ),
          EventMethod(
            eventName: 'user.deleted',
            handler: (user) async => print('User deleted: $user'),
            priority: EventPriority.critical,
            once: true,
          ),
        ];

        expect(methods[0].eventName, equals('user.created'));
        expect(methods[0].priority, equals(EventPriority.normal));
        expect(methods[0].once, isFalse);

        expect(methods[1].priority, equals(EventPriority.high));
        expect(methods[2].once, isTrue);
      });

      test('should support different handler signatures', () {
        // Handler that returns void
        final voidMethod = EventMethod(
          eventName: 'void.handler',
          handler: (payload) async {
            // Do something without returning
          },
        );

        // Handler that returns a value
        final valueMethod = EventMethod(
          eventName: 'value.handler',
          handler: (payload) async => 'result',
        );

        // Handler that processes different payload types
        final typedMethod = EventMethod(
          eventName: 'typed.handler',
          handler: (payload) async {
            if (payload is String) {
              // Process string payload
            }
          },
        );

        expect(voidMethod.handler, isNotNull);
        expect(valueMethod.handler, isNotNull);
        expect(typedMethod.handler, isNotNull);
      });
    });

    group('Edge cases', () {
      test('should handle empty event names', () {
        final method = EventMethod(
          eventName: '',
          handler: (payload) async {},
        );

        expect(method.eventName, isEmpty);
      });

      test('should handle very long event names', () {
        final longEventName = 'a' * 1000;
        final method = EventMethod(
          eventName: longEventName,
          handler: (payload) async {},
        );

        expect(method.eventName, equals(longEventName));
        expect(method.eventName.length, equals(1000));
      });

      test('should handle special characters in event names', () {
        const specialEventName = 'user.created@v1.0:with-params';
        final method = EventMethod(
          eventName: specialEventName,
          handler: (payload) async {},
        );

        expect(method.eventName, equals(specialEventName));
      });
    });
  });
}
