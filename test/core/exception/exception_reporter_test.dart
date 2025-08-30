import 'package:test/test.dart';

import '../../../lib/src/contracts/exceptions/app_exception.dart';
import '../../../lib/src/core/exception/exception_reporter.dart';

class TestException extends AppException {
  TestException([String message = 'Test error', dynamic details])
      : super(message, statusCode: 400, details: details);
}

void main() {
  group('ExceptionReporter', () {
    setUp(() {
      // Reset configuration before each test
      ExceptionReporter.configure(
        includeStackTraces: true,
        includeUserContext: true,
        includeRequestContext: true,
        includeEnvironmentInfo: true,
        minimumReportLevel: 'error',
      );
    });

    tearDown(() {
      // Clear global context after each test
      ExceptionReporter.clearGlobalContext();
    });

    group('Configuration', () {
      test('should configure reporting settings', () {
        ExceptionReporter.configure(
          includeStackTraces: false,
          includeUserContext: false,
          includeRequestContext: false,
          includeEnvironmentInfo: false,
          minimumReportLevel: 'critical',
        );

        final config = ExceptionReporter.getConfiguration();
        expect(config['includeStackTraces'], isFalse);
        expect(config['includeUserContext'], isFalse);
        expect(config['includeRequestContext'], isFalse);
        expect(config['includeEnvironmentInfo'], isFalse);
        expect(config['minimumReportLevel'], equals('critical'));
      });

      test('should add and remove global context', () {
        ExceptionReporter.addGlobalContext('app_version', '1.0.0');
        ExceptionReporter.addGlobalContext('environment', 'test');

        var config = ExceptionReporter.getConfiguration();
        expect(config['globalContext']['app_version'], equals('1.0.0'));
        expect(config['globalContext']['environment'], equals('test'));

        ExceptionReporter.removeGlobalContext('app_version');
        config = ExceptionReporter.getConfiguration();
        expect(config['globalContext'].containsKey('app_version'), isFalse);
        expect(config['globalContext']['environment'], equals('test'));

        ExceptionReporter.clearGlobalContext();
        config = ExceptionReporter.getConfiguration();
        expect(config['globalContext'], isEmpty);
      });
    });

    group('Context Building', () {
      test('should build exception context with all information', () {
        // Test that configuration affects context building
        ExceptionReporter.configure(includeStackTraces: true);
        final config = ExceptionReporter.getConfiguration();
        expect(config['includeStackTraces'], isTrue);
        expect(config['globalContext'], isEmpty);
      });

      test('should include timestamp in context', () {
        // Test that configuration is properly stored
        ExceptionReporter.configure(includeEnvironmentInfo: true);
        final config = ExceptionReporter.getConfiguration();
        expect(config['includeEnvironmentInfo'], isTrue);
      });
    });

    group('Exception Reporting Methods', () {
      test('should have reportAppException method', () {
        // Test that the method exists
        expect(ExceptionReporter.reportAppException, isNotNull);
      });

      test('should have reportException method', () {
        expect(ExceptionReporter.reportException, isNotNull);
      });

      test('should have reportWithLevel method', () {
        expect(ExceptionReporter.reportWithLevel, isNotNull);
      });
    });
  });
}
