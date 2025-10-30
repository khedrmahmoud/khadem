import 'package:khadem/src/core/session/session_id_generator.dart';
import 'package:test/test.dart';

void main() {
  group('SessionIdGenerator', () {
    late SessionIdGenerator generator;

    setUp(() {
      generator = SessionIdGenerator();
    });

    test('should generate a non-empty session ID', () {
      final sessionId = generator.generate();

      expect(sessionId, isNotEmpty);
      expect(sessionId.length, equals(32));
    });

    test('should generate unique session IDs', () {
      final sessionId1 = generator.generate();
      final sessionId2 = generator.generate();

      expect(sessionId1, isNot(equals(sessionId2)));
    });

    test('should generate valid hex string', () {
      final sessionId = generator.generate();

      // Should only contain valid hex characters
      expect(sessionId, matches(r'^[a-f0-9]{32}$'));
    });
  });
}
