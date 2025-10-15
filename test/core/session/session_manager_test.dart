import 'package:test/test.dart';
import 'dart:io';
import 'package:khadem/src/core/session/session_manager.dart';
import 'package:khadem/src/core/session/drivers/file_session_driver.dart';
import 'package:khadem/src/contracts/session/session_driver_registry.dart';

void main() {
  group('SessionManager', () {
    late SessionManager sessionManager;
    late Directory tempDir;
    late SessionDriverRegistry registry;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('session_manager_test_');
      registry = SessionDriverRegistry();
      final fileDriver = FileSessionDriver(tempDir.path);
      registry.registerDriver('file', fileDriver);
      sessionManager = SessionManager(
        driverRegistry: registry,
        driverName: 'file',
        maxAge: const Duration(hours: 24),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should create a new session', () async {
      final initialData = {'user_id': 123, 'username': 'testuser'};
      final sessionId = await sessionManager.createSession(initialData);

      expect(sessionId, isNotEmpty);
      expect(sessionId.length, equals(32));

      // Verify session was created
      final sessionData = await sessionManager.getSession(sessionId);
      expect(sessionData, isNotNull);
      expect(sessionData!['data'], equals(initialData));
    });

    test('should get session data', () async {
      final initialData = {'key': 'value'};
      final sessionId = await sessionManager.createSession(initialData);

      final retrievedData = await sessionManager.getSession(sessionId);
      expect(retrievedData, isNotNull);
      expect(retrievedData!['data'], equals(initialData));
    });

    test('should return null for non-existent session', () async {
      final retrievedData = await sessionManager.getSession('non_existent');
      expect(retrievedData, isNull);
    });

    test('should update session data', () async {
      final initialData = {'initial': 'data'};
      final sessionId = await sessionManager.createSession(initialData);

      final newData = {'updated': 'data'};
      await sessionManager.updateSession(sessionId, newData);

      final updatedData = await sessionManager.getSession(sessionId);
      expect(updatedData, isNotNull);
      expect(updatedData!['data'], equals({'initial': 'data', 'updated': 'data'}));
    });

    test('should get and set session values', () async {
      final sessionId = await sessionManager.createSession();

      // Set a value
      await sessionManager.setSessionValue(sessionId, 'user_id', 456);
      await sessionManager.setSessionValue(sessionId, 'username', 'johndoe');

      // Get values
      final userId = await sessionManager.getSessionValue(sessionId, 'user_id');
      final username = await sessionManager.getSessionValue(sessionId, 'username');

      expect(userId, equals(456));
      expect(username, equals('johndoe'));
    });

    test('should remove session values', () async {
      final sessionId = await sessionManager.createSession({'key1': 'value1', 'key2': 'value2'});

      // Remove one value
      await sessionManager.removeSessionValue(sessionId, 'key1');

      // Check remaining data
      final sessionData = await sessionManager.getSession(sessionId);
      expect(sessionData!['data'], equals({'key2': 'value2'}));
    });

    test('should destroy session', () async {
      final sessionId = await sessionManager.createSession({'key': 'value'});

      // Verify session exists
      var sessionData = await sessionManager.getSession(sessionId);
      expect(sessionData, isNotNull);

      // Destroy session
      await sessionManager.destroySession(sessionId);

      // Verify session is gone
      sessionData = await sessionManager.getSession(sessionId);
      expect(sessionData, isNull);
    });

    test('should regenerate session ID', () async {
      final initialData = {'user_id': 789};
      final oldSessionId = await sessionManager.createSession(initialData);

      final newSessionId = await sessionManager.regenerateSession(oldSessionId);

      expect(newSessionId, isNot(equals(oldSessionId)));

      // Old session should be gone
      final oldSessionData = await sessionManager.getSession(oldSessionId);
      expect(oldSessionData, isNull);

      // New session should have the data
      final newSessionData = await sessionManager.getSession(newSessionId);
      expect(newSessionData, isNotNull);
      expect(newSessionData!['data'], equals(initialData));
    });

    test('should handle expired sessions', () async {
      // Create a session manager with very short max age
      final shortLivedRegistry = SessionDriverRegistry();
      final shortLivedDriver = FileSessionDriver(tempDir.path);
      shortLivedRegistry.registerDriver('file', shortLivedDriver);
      final shortLivedManager = SessionManager(
        driverRegistry: shortLivedRegistry,
        driverName: 'file',
        maxAge: const Duration(milliseconds: 1),
      );

      final sessionId = await shortLivedManager.createSession({'key': 'value'});

      // Wait a bit for session to expire
      await Future.delayed(const Duration(milliseconds: 2));

      // Try to get the session - should return null due to expiration
      final sessionData = await shortLivedManager.getSession(sessionId);
      expect(sessionData, isNull);
    });

    test('should flash data to session', () async {
      final sessionId = await sessionManager.createSession();

      // Flash some data
      await sessionManager.flash(sessionId, 'message', 'Hello World');
      await sessionManager.flash(sessionId, 'error', 'Something went wrong');

      // Get flashed data
      final message = await sessionManager.getFlashed(sessionId, 'message');
      final error = await sessionManager.getFlashed(sessionId, 'error');

      expect(message, equals('Hello World'));
      expect(error, equals('Something went wrong'));

      // Data should be cleared after retrieval
      final messageAgain = await sessionManager.getFlashed(sessionId, 'message');
      expect(messageAgain, isNull);
    });

    test('should handle old input flashing', () async {
      final sessionId = await sessionManager.createSession();
      final inputData = {'email': 'test@example.com', 'name': 'Test User'};

      // Flash old input
      await sessionManager.flashOldInput(sessionId, inputData);

      // Get old input
      final oldInput = await sessionManager.getOldInput(sessionId);
      expect(oldInput, equals(inputData));

      // Should be cleared after retrieval
      final oldInputAgain = await sessionManager.getOldInput(sessionId);
      expect(oldInputAgain, isNull);
    });

    test('should check if session is valid', () async {
      final sessionId = await sessionManager.createSession();

      // Should be valid initially
      final isValid = await sessionManager.hasValidSession(sessionId);
      expect(isValid, isTrue);

      // Destroy session
      await sessionManager.destroySession(sessionId);

      // Should not be valid anymore
      final isValidAfterDestroy = await sessionManager.hasValidSession(sessionId);
      expect(isValidAfterDestroy, isFalse);
    });

    test('should cleanup expired sessions', () async {
      // Create sessions with different ages
      final expiredSessionId = await sessionManager.createSession({'expired': true});

      // Manually modify the session file to make it old
      final fileDriver = FileSessionDriver(tempDir.path);
      final expiredData = {
        'created_at': DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
        'last_activity': DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
        'data': {'expired': true},
      };
      await fileDriver.write(expiredSessionId, expiredData);

      final validSessionId = await sessionManager.createSession({'valid': true});

      // Cleanup expired sessions
      await sessionManager.cleanupExpiredSessions();

      // Expired session should be gone
      final expiredExists = await sessionManager.hasValidSession(expiredSessionId);
      expect(expiredExists, isFalse);

      // Valid session should still exist
      final validExists = await sessionManager.hasValidSession(validSessionId);
      expect(validExists, isTrue);
    });

    test('should handle empty session ID gracefully', () async {
      // Empty session ID should return null
      final result = await sessionManager.getSession('');
      expect(result, isNull);

      // Destroying empty session should not throw
      await sessionManager.destroySession('');
      // No assertion needed, just verify it doesn't throw
    });
  });

  group('SessionManager Driver Management', () {
    late SessionManager sessionManager;
    late Directory tempDir1;
    late Directory tempDir2;
    late SessionDriverRegistry registry;

    setUp(() async {
      tempDir1 = await Directory.systemTemp.createTemp('session_manager_test_1_');
      tempDir2 = await Directory.systemTemp.createTemp('session_manager_test_2_');
      registry = SessionDriverRegistry();

      final fileDriver1 = FileSessionDriver(tempDir1.path);
      final fileDriver2 = FileSessionDriver(tempDir2.path);

      registry.registerDriver('file1', fileDriver1);
      registry.registerDriver('file2', fileDriver2);

      sessionManager = SessionManager(
        driverRegistry: registry,
        driverName: 'file1',
        maxAge: const Duration(hours: 24),
      );
    });

    tearDown(() async {
      if (await tempDir1.exists()) {
        await tempDir1.delete(recursive: true);
      }
      if (await tempDir2.exists()) {
        await tempDir2.delete(recursive: true);
      }
    });

    test('should get current driver name', () {
      expect(sessionManager.driverName, equals('file1'));
    });

    test('should get all available driver names', () {
      final driverNames = sessionManager.driverNames;
      expect(driverNames, contains('file1'));
      expect(driverNames, contains('file2'));
    });

    test('should switch to different driver', () async {
      // Create session with first driver
      final sessionId = await sessionManager.createSession({'test': 'data'});
      expect(sessionManager.driverName, equals('file1'));

      // Switch to second driver
      await sessionManager.switchDriver('file2');
      expect(sessionManager.driverName, equals('file2'));

      // Session should not be available on new driver
      final sessionData = await sessionManager.getSession(sessionId);
      expect(sessionData, isNull);
    });

    test('should throw error when switching to non-existent driver', () async {
      expect(
        () async => sessionManager.switchDriver('non_existent'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}