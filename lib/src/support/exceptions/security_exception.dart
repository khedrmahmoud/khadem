import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a security violation is detected.
///
/// This exception is typically thrown when:
/// - Path traversal attempts are detected
/// - Invalid file access is attempted
/// - Security boundaries are violated
class SecurityException extends AppException {
  SecurityException(super.message, {super.details})
    : super(
        statusCode: 403,
        title: 'Security Violation',
        type: 'security_violation',
      );
}
