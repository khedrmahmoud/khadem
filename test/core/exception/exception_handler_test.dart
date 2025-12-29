import 'package:khadem/khadem.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'exception_handler_test.mocks.dart';

@GenerateMocks([Logger])
void main() {
  group('ExceptionHandler', () {
    late ExceptionHandler handler;
    late MockLogger mockLogger;

    setUp(() {
      handler = ExceptionHandler();
      mockLogger = MockLogger();

      // Register mock logger
      final container = ContainerProvider.instance;
      container.instance<Logger>(mockLogger);

      // Mock logger methods
      when(mockLogger.error(
        any,
        context: anyNamed('context'),
        stackTrace: anyNamed('stackTrace'),
      ),).thenReturn(null);
      when(mockLogger.warning(
        any,
        context: anyNamed('context'),
        stackTrace: anyNamed('stackTrace'),
      ),).thenReturn(null);
      when(mockLogger.critical(
        any,
        context: anyNamed('context'),
        stackTrace: anyNamed('stackTrace'),
      ),).thenReturn(null);
    });

    tearDown(() {
      ContainerProvider.instance.flush();
    });

    test('should handle AppException and return ErrorResult', () async {
      final exception = AppExceptionTest('Test Error', statusCode: 400);

      final result = await handler.handle(exception);

      expect(result, isA<ErrorResult>());
      expect(result.statusCode, 400);
      expect(result.title, 'Application Error');
      expect(result.message, 'Test Error');
      expect(result.type, 'about:blank');
    });

    test('should handle generic Exception with 500 status', () async {
      final exception = Exception('Generic Error');

      final result = await handler.handle(exception);

      expect(result, isA<ErrorResult>());
      expect(result.statusCode, 500);
      expect(result.title, 'Internal Server Error');
      expect(result.message, 'An unexpected error occurred.');
      expect(result.type, 'about:blank');
    });

    test('should use custom handler if registered', () async {
      handler.register<CustomException>((error, stack) async {
        return const ErrorResult(
          statusCode: 418,
          title: 'I am a teapot',
          message: 'Custom Handler',
        );
      });

      final result = await handler.handle(CustomException());

      expect(result.statusCode, 418);
      expect(result.title, 'I am a teapot');
      expect(result.message, 'Custom Handler');
    });
  });
}

class AppExceptionTest extends AppException {
  AppExceptionTest(super.message, {super.statusCode});
}

class CustomException implements Exception {}
