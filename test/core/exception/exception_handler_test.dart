import 'package:khadem/khadem.dart';
import 'package:khadem/src/contracts/exceptions/app_exception.dart';
import 'package:khadem/src/contracts/exceptions/exception_handler_contract.dart';
import 'package:khadem/src/core/exception/exception_handler.dart';
import 'package:khadem/src/core/http/response/response.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'exception_handler_test.mocks.dart';

@GenerateMocks([Response, Logger])
void main() {
  group('ExceptionHandler', () {
    late ExceptionHandler handler;
    late MockResponse mockResponse;
    late MockLogger mockLogger;

    setUp(() {
      handler = ExceptionHandler();
      mockResponse = MockResponse();
      mockLogger = MockLogger();

      // Register mock logger
      final container = ContainerProvider.instance;
      container.instance<Logger>(mockLogger);
      
      // Mock logger methods
      when(mockLogger.error(any, context: anyNamed('context'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);
      when(mockLogger.warning(any, context: anyNamed('context'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);
      when(mockLogger.critical(any, context: anyNamed('context'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);
      
      // Default behavior for mock response
      when(mockResponse.status(any)).thenReturn(mockResponse);
      when(mockResponse.header(any, any)).thenReturn(mockResponse);
      when(mockResponse.sent).thenReturn(false);
    });

    tearDown(() {
      ContainerProvider.instance.flush();
    });

    test('should handle AppException with RFC 7807 JSON response', () async {
      final exception = AppExceptionTest('Test Error', statusCode: 400);
      
      await handler.handle(mockResponse, exception);

      verify(mockResponse.status(400)).called(1);
      verify(mockResponse.problem(
        type: 'about:blank',
        title: 'Application Error',
        status: 400,
        detail: 'Test Error',
        instance: null,
        extensions: anyNamed('extensions'),
      )).called(1);
    });

    test('should handle generic Exception with 500 status', () async {
      final exception = Exception('Generic Error');
      
      await handler.handle(mockResponse, exception);

      verify(mockResponse.status(500)).called(1);
      verify(mockResponse.problem(
        type: 'about:blank',
        title: 'Internal Server Error',
        status: 500,
        detail: anyNamed('detail'),
        extensions: anyNamed('extensions'),
      )).called(1);
    });

    test('should use custom handler if registered', () async {
      bool customHandlerCalled = false;
      handler.register<CustomException>((res, error, stack) async {
        customHandlerCalled = true;
      });

      await handler.handle(mockResponse, CustomException());

      expect(customHandlerCalled, isTrue);
      verifyNever(mockResponse.problem(
        title: anyNamed('title'),
        status: anyNamed('status'),
      ));
    });
  });
}

class AppExceptionTest extends AppException {
  AppExceptionTest(String message, {int statusCode = 500})
      : super(message, statusCode: statusCode);
}

class CustomException implements Exception {}
