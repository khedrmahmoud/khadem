import 'package:test/test.dart';
import 'package:khadem/src/core/session/session_validator.dart';

void main() {
  group('SessionValidator', () {
    late SessionValidator validator;

    setUp(() {
      validator = SessionValidator();
    });

    test('should detect expired sessions', () {
      final expiredData = {
        'last_activity': DateTime.now().subtract(Duration(hours: 25)).toIso8601String(),
        'data': {'key': 'value'}
      };

      final validData = {
        'last_activity': DateTime.now().toIso8601String(),
        'data': {'key': 'value'}
      };

      expect(validator.isExpired(expiredData, Duration(hours: 24)), isTrue);
      expect(validator.isExpired(validData, Duration(hours: 24)), isFalse);
    });

    test('should handle missing last_activity field', () {
      final dataWithoutActivity = {
        'data': {'key': 'value'}
      };

      expect(validator.isExpired(dataWithoutActivity, Duration(hours: 24)), isFalse);
    });

    test('should handle invalid last_activity format', () {
      final dataWithInvalidActivity = {
        'last_activity': 'invalid-date-format',
        'data': {'key': 'value'}
      };

      expect(validator.isExpired(dataWithInvalidActivity, Duration(hours: 24)), isFalse);
    });

    test('should update last accessed timestamp', () {
      final data = {
        'last_activity': '2023-01-01T00:00:00.000Z',
        'data': {'key': 'value'}
      };

      final oldActivity = data['last_activity'];

      validator.updateLastAccessed(data);

      expect(data['last_activity'], isNot(equals(oldActivity)));
      expect(DateTime.tryParse(data['last_activity'] as String), isNotNull);
    });

    test('should initialize session data correctly', () {
      final initialData = {'user_id': 123, 'username': 'testuser'};
      final sessionData = validator.initializeSessionData(initialData);

      expect(sessionData, contains('created_at'));
      expect(sessionData, contains('last_activity'));
      expect(sessionData, contains('data'));
      expect(sessionData['data'], equals(initialData));

      // Verify timestamps are valid
      expect(DateTime.tryParse(sessionData['created_at'] as String), isNotNull);
      expect(DateTime.tryParse(sessionData['last_activity'] as String), isNotNull);
    });

    test('should initialize session data with empty initial data', () {
      final sessionData = validator.initializeSessionData();

      expect(sessionData, contains('created_at'));
      expect(sessionData, contains('last_activity'));
      expect(sessionData, contains('data'));
      expect(sessionData['data'], isEmpty);
    });
  });
}