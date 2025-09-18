import 'package:test/test.dart';

import '../../../lib/src/contracts/exceptions/app_exception.dart';
import '../../../lib/src/support/exceptions/bad_request_exception.dart';
import '../../../lib/src/support/exceptions/forbidden_exception.dart';
import '../../../lib/src/support/exceptions/not_found_exception.dart';
import '../../../lib/src/support/exceptions/too_many_requests_exception.dart';
import '../../../lib/src/support/exceptions/unauthorized_exception.dart';
import '../../../lib/src/support/exceptions/validation_exception.dart';

void main() {
  group('Exception Classes', () {
    group('BadRequestException', () {
      test('should have correct status code', () {
        final exception = BadRequestException();
        expect(exception.message, equals('Bad request'));
        expect(exception.statusCode, equals(400));
      });

      test('should create with details', () {
        final exception = BadRequestException('Invalid input', {'field': 'email'});
        expect(exception.details, equals({'field': 'email'}));
      });

      test('should serialize to response', () {
        final exception = BadRequestException('Test error', {'test': 'data'});
        final response = exception.toResponse();
        expect(response['message'], equals('Test error'));
        expect(response['details'], equals({'test': 'data'}));
      });
    });

    group('UnauthorizedException', () {
      test('should have correct status code', () {
        final exception = UnauthorizedException('Not authorized');
        expect(exception.message, equals('Not authorized'));
        expect(exception.statusCode, equals(401));
      });

      test('should create with default message', () {
        final exception = UnauthorizedException();
        expect(exception.message, equals('Unauthorized'));
        expect(exception.statusCode, equals(401));
      });
    });

    group('ForbiddenException', () {
      test('should have correct status code', () {
        final exception = ForbiddenException('Access forbidden');
        expect(exception.message, equals('Access forbidden'));
        expect(exception.statusCode, equals(403));
      });

      test('should create with details', () {
        final exception = ForbiddenException('Insufficient permissions', {'required': 'admin'});
        expect(exception.details, equals({'required': 'admin'}));
      });
    });

    group('NotFoundException', () {
      test('should have correct status code', () {
        final exception = NotFoundException();
        expect(exception.message, equals('Resource not found'));
        expect(exception.statusCode, equals(404));
      });

      test('should create with default message', () {
        final exception = NotFoundException();
        expect(exception.message, equals('Resource not found'));
        expect(exception.statusCode, equals(404));
      });
    });

    group('ValidationException', () {
      test('should have correct status code', () {
        final errors = {'email': 'required', 'password': 'min_length'};
        final exception = ValidationException(errors);
        expect(exception.statusCode, equals(422));
      });

      test('should create with validation errors', () {
        final errors = {'email': 'required', 'password': 'min_length'};
        final exception = ValidationException(errors);
        expect(exception.details, equals(errors));
      });
    });

    group('TooManyRequestsException', () {
      test('should have correct status code', () {
        final exception = TooManyRequestsException('Rate limit exceeded');
        expect(exception.message, equals('Rate limit exceeded'));
        expect(exception.statusCode, equals(429));
      });

      test('should create with retry after', () {
        final exception = TooManyRequestsException('Rate limit exceeded', null, 60);
        expect(exception.retryAfter, equals(60));
      });

      test('should create without retry after', () {
        final exception = TooManyRequestsException('Rate limit exceeded');
        expect(exception.retryAfter, isNull);
      });

      test('should include retry after in response', () {
        final exception = TooManyRequestsException('Rate limit exceeded', null, 60);
        final response = exception.toResponse();
        expect(response['retry_after'], equals(60));
      });
    });

    group('Exception Serialization', () {
      test('should serialize all exception types to response', () {
        final exceptions = [
          BadRequestException(),
          UnauthorizedException(),
          ForbiddenException(),
          NotFoundException('Not found'),
          ValidationException({'field': 'error'}),
          TooManyRequestsException(),
        ];

        for (final exception in exceptions) {
          final response = exception.toResponse();
          expect(response['message'], isNotEmpty);
          // Only check for details if they exist
          if (exception.details != null) {
            expect(response.containsKey('details'), isTrue);
          }
        }
      });

      test('should handle null details in serialization', () {
        final exception = BadRequestException('Test');
        final response = exception.toResponse();
        expect(response.containsKey('details'), isFalse);
      });

      test('should include details when present', () {
        final exception = ValidationException({'field': 'error'});
        final response = exception.toResponse();
        expect(response['details'], equals({'field': 'error'}));
      });
    });

    group('Exception Hierarchy', () {
      test('should all extend AppException', () {
        final exceptions = [
          BadRequestException('test'),
          UnauthorizedException('test'),
          ForbiddenException('test'),
          NotFoundException('test'),
          ValidationException({'test': 'error'}),
          TooManyRequestsException('test'),
        ];

        for (final exception in exceptions) {
          expect(exception, isA<AppException>());
        }
      });

      test('should maintain correct inheritance chain', () {
        final exception = BadRequestException('test');
        expect(exception, isA<AppException>());
        expect(exception, isA<BadRequestException>());
      });
    });
  });
}
