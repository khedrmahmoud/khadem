import 'package:test/test.dart';

import '../../../lib/src/contracts/events/event_system_interface.dart';
import '../../../lib/src/core/events/event_registration.dart';

void main() {
  group('EventRegistration', () {
    late EventRegistration registration;

    setUp(() {
      registration = EventRegistration(
        (payload) async => print('test'),
        EventPriority.normal,
        false,
      );
    });

    group('Constructor', () {
      test('should create registration with provided values', () {
        final listener = (payload) async {};
        const priority = EventPriority.high;
        const once = true;

        final reg = EventRegistration(listener, priority, once);

        expect(reg.listener, same(listener));
        expect(reg.priority, equals(priority));
        expect(reg.once, equals(once));
        expect(reg.removed, isFalse);
      });

      test('should default once to false', () {
        final reg = EventRegistration((payload) async {}, EventPriority.normal, false);
        expect(reg.once, isFalse);
      });

      test('should default removed to false', () {
        final reg = EventRegistration((payload) async {}, EventPriority.normal, false);
        expect(reg.removed, isFalse);
      });
    });

    group('compareTo()', () {
      test('should return negative when this has higher priority', () {
        final highPriority = EventRegistration(
          (payload) async {},
          EventPriority.high,
          false,
        );
        final lowPriority = EventRegistration(
          (payload) async {},
          EventPriority.low,
          false,
        );

        final result = highPriority.compareTo(lowPriority);
        expect(result, lessThan(0));
      });

      test('should return positive when this has lower priority', () {
        final lowPriority = EventRegistration(
          (payload) async {},
          EventPriority.low,
          false,
        );
        final highPriority = EventRegistration(
          (payload) async {},
          EventPriority.high,
          false,
        );

        final result = lowPriority.compareTo(highPriority);
        expect(result, greaterThan(0));
      });

      test('should return zero when priorities are equal', () {
        final reg1 = EventRegistration(
          (payload) async {},
          EventPriority.normal,
          false,
        );
        final reg2 = EventRegistration(
          (payload) async {},
          EventPriority.normal,
          false,
        );

        final result = reg1.compareTo(reg2);
        expect(result, equals(0));
      });

      test('should handle all priority levels correctly', () {
        final priorities = [
          EventPriority.low,
          EventPriority.normal,
          EventPriority.high,
          EventPriority.critical,
        ];

        for (var i = 0; i < priorities.length - 1; i++) {
          final lower = EventRegistration((payload) async {}, priorities[i], false);
          final higher = EventRegistration((payload) async {}, priorities[i + 1], false);

          expect(lower.compareTo(higher), greaterThan(0));
          expect(higher.compareTo(lower), lessThan(0));
        }
      });
    });

    group('Properties', () {
      test('should allow setting removed flag', () {
        expect(registration.removed, isFalse);

        registration.removed = true;
        expect(registration.removed, isTrue);

        registration.removed = false;
        expect(registration.removed, isFalse);
      });

      test('should maintain listener reference', () {
        final originalListener = registration.listener;
        expect(originalListener, isNotNull);

        // Listener should remain the same
        expect(registration.listener, same(originalListener));
      });

      test('should maintain priority value', () {
        expect(registration.priority, equals(EventPriority.normal));

        final highPriority = EventRegistration(
          (payload) async {},
          EventPriority.high,
          false,
        );
        expect(highPriority.priority, equals(EventPriority.high));
      });

      test('should maintain once flag', () {
        expect(registration.once, isFalse);

        final onceReg = EventRegistration(
          (payload) async {},
          EventPriority.normal,
          true,
        );
        expect(onceReg.once, isTrue);
      });
    });

    group('Integration with sorting', () {
      test('should sort correctly in list by priority', () {
        final registrations = [
          EventRegistration((payload) async {}, EventPriority.low, false),
          EventRegistration((payload) async {}, EventPriority.critical, false),
          EventRegistration((payload) async {}, EventPriority.normal, false),
          EventRegistration((payload) async {}, EventPriority.high, false),
        ];

        registrations.sort((a, b) => a.compareTo(b));

        expect(registrations[0].priority, equals(EventPriority.critical));
        expect(registrations[1].priority, equals(EventPriority.high));
        expect(registrations[2].priority, equals(EventPriority.normal));
        expect(registrations[3].priority, equals(EventPriority.low));
      });

      test('should maintain stable sort for same priorities', () {
        final reg1 = EventRegistration((payload) async => print('first'), EventPriority.normal, false);
        final reg2 = EventRegistration((payload) async => print('second'), EventPriority.normal, false);
        final reg3 = EventRegistration((payload) async => print('third'), EventPriority.normal, false);

        final registrations = [reg1, reg2, reg3];
        registrations.sort((a, b) => a.compareTo(b));

        // Order should be preserved for same priority
        expect(registrations[0], same(reg1));
        expect(registrations[1], same(reg2));
        expect(registrations[2], same(reg3));
      });
    });

    group('Usage in EventSystem context', () {
      test('should work with different listener types', () {
        // Sync listener
        final syncReg = EventRegistration(
          (payload) => print('sync'),
          EventPriority.normal,
          false,
        );

        // Async listener
        final asyncReg = EventRegistration(
          (payload) async => print('async'),
          EventPriority.normal,
          false,
        );

        // Listener with complex payload handling
        final complexReg = EventRegistration(
          (payload) async {
            if (payload is Map<String, dynamic>) {
              print('Complex payload: $payload');
            }
          },
          EventPriority.normal,
          false,
        );

        expect(syncReg.listener, isNotNull);
        expect(asyncReg.listener, isNotNull);
        expect(complexReg.listener, isNotNull);
      });

      test('should handle once flag for cleanup', () {
        final onceReg = EventRegistration(
          (payload) async => print('once'),
          EventPriority.normal,
          true,
        );

        expect(onceReg.once, isTrue);
        expect(onceReg.removed, isFalse);

        // Simulate removal after execution
        onceReg.removed = true;
        expect(onceReg.removed, isTrue);
      });
    });
  });
}
