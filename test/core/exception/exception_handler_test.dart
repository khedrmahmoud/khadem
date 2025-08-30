import 'package:test/test.dart';

import '../../../lib/src/contracts/exceptions/app_exception.dart';
import '../../../lib/src/core/exception/exception_handler.dart';

class TestException extends AppException {
  TestException([String message = 'Test error', dynamic details])
      : super(message, statusCode: 400, details: details);
}

void main() {
  group('ExceptionHandler', () {
    setUp(() {
      // Reset configuration before each test
      ExceptionHandler.configure(
        showDetailedErrors: true,
        includeStackTracesInResponse: false,
      );
    });

    tearDown(() {
      // Reset configuration after each test
      ExceptionHandler.configure(
        showDetailedErrors: true,
        includeStackTracesInResponse: false,
      );
    });

    group('Configuration', () {
      test('should configure handler settings', () {
        ExceptionHandler.configure(
          showDetailedErrors: false,
          includeStackTracesInResponse: true,
        );

        final config = ExceptionHandler.getConfiguration();
        expect(config['showDetailedErrors'], isFalse);
        expect(config['includeStackTracesInResponse'], isTrue);
      });

      test('should configure with custom formatter', () {
        Map<String, dynamic> customFormatter(AppException e) {
          return {'custom': true, 'msg': e.message};
        }

        ExceptionHandler.configure(
          showDetailedErrors: true,
          includeStackTracesInResponse: false,
          customFormatter: customFormatter,
        );

        final config = ExceptionHandler.getConfiguration();
        expect(config['hasCustomFormatter'], isTrue);
      });
    });

    group('Exception Handling Methods', () {
      test('should have handle method', () {
        expect(ExceptionHandler.handle, isNotNull);
      });

      test('should have handleWithFormat method', () {
        expect(ExceptionHandler.handleWithFormat, isNotNull);
      });

      test('should have getConfiguration method', () {
        final config = ExceptionHandler.getConfiguration();
        expect(config, isA<Map<String, dynamic>>());
        expect(config.containsKey('showDetailedErrors'), isTrue);
        expect(config.containsKey('includeStackTracesInResponse'), isTrue);
        expect(config.containsKey('hasCustomFormatter'), isTrue);
      });
    });

    group('Configuration Validation', () {
      test('should return correct default configuration', () {
        final config = ExceptionHandler.getConfiguration();
        expect(config['showDetailedErrors'], isTrue);
        expect(config['includeStackTracesInResponse'], isFalse);
        expect(config['hasCustomFormatter'], isFalse);
      });

      test('should update configuration correctly', () {
        ExceptionHandler.configure(
          showDetailedErrors: false,
          includeStackTracesInResponse: true,
        );

        final config = ExceptionHandler.getConfiguration();
        expect(config['showDetailedErrors'], isFalse);
        expect(config['includeStackTracesInResponse'], isTrue);
      });
    });
  });
}
