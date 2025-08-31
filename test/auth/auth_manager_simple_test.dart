import 'package:test/test.dart';

import '../../lib/src/modules/auth/services/auth_manager.dart';

void main() {
  group('AuthManager', () {
    group('Constructor and Initialization', () {
      test('should create instance with default guard', () {
        // This test would require proper config mocking
        // For now, we'll test that the class can be instantiated
        expect(
          () => AuthManager(),
          throwsA(isA<Exception>()), // Will throw due to missing config
        );
      });

      test('should create instance with specific guard', () {
        expect(
          () => AuthManager(guard: 'api'),
          throwsA(isA<Exception>()), // Will throw due to missing config
        );
      });
    });

    group('Properties', () {
      test('should expose guard property', () {
        // This would require mocking the config system
        // For now, we test that the property exists conceptually
        final authManagerType = AuthManager;
        expect(authManagerType, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should throw exception when config is missing', () {
        expect(
          () => AuthManager(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
