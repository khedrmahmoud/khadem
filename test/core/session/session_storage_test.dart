import 'dart:io';

import 'package:khadem/src/core/session/session_storage.dart';
import 'package:test/test.dart';

void main() {
  group('FileSessionStorage', () {
    late FileSessionStorage storage;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('session_test_');
      storage = FileSessionStorage(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should write and read session data', () async {
      const sessionId = 'test_session_123';
      final testData = {
        'user_id': 123,
        'username': 'testuser',
        'created_at': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'data': {'key': 'value'},
      };

      // Write data
      await storage.write(sessionId, testData);

      // Read data
      final readData = await storage.read(sessionId);

      expect(readData, isNotNull);
      expect(readData!['user_id'], equals(123));
      expect(readData['username'], equals('testuser'));
      expect(readData['data'], equals({'key': 'value'}));
    });

    test('should return null for non-existent session', () async {
      final readData = await storage.read('non_existent_session');
      expect(readData, isNull);
    });

    test('should delete session data', () async {
      const sessionId = 'test_session_delete';
      final testData = {'key': 'value'};

      // Write data
      await storage.write(sessionId, testData);

      // Verify it exists
      var readData = await storage.read(sessionId);
      expect(readData, isNotNull);

      // Delete data
      await storage.delete(sessionId);

      // Verify it's gone
      readData = await storage.read(sessionId);
      expect(readData, isNull);
    });

    test('should cleanup expired sessions', () async {
      const sessionId1 = 'expired_session';
      const sessionId2 = 'valid_session';

      final expiredData = {
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
        'last_activity': DateTime.now()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
        'data': {'expired': true},
      };

      final validData = {
        'created_at': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'data': {'valid': true},
      };

      // Write both sessions
      await storage.write(sessionId1, expiredData);
      await storage.write(sessionId2, validData);

      // Manually set the expired file to be old
      final expiredFile = File('${tempDir.path}/$sessionId1.session');
      final oldTime = DateTime.now().subtract(const Duration(hours: 25));
      await expiredFile.setLastModified(oldTime);

      // Cleanup with 1 hour max age
      await storage.cleanup(const Duration(hours: 1));

      // Check that expired session is gone
      final expiredRead = await storage.read(sessionId1);
      expect(expiredRead, isNull);

      // Check that valid session still exists
      final validRead = await storage.read(sessionId2);
      expect(validRead, isNotNull);
    });

    test('should handle corrupted session files gracefully', () async {
      const sessionId = 'corrupted_session';

      // Create a corrupted session file manually
      final file = File('${tempDir.path}/$sessionId.session');
      await file.writeAsString('invalid json content');

      // Try to read it
      final readData = await storage.read(sessionId);

      // Should return null and clean up the corrupted file
      expect(readData, isNull);
      expect(await file.exists(), isFalse);
    });
  });
}
