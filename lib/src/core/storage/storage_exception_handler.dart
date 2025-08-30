import '../../contracts/exceptions/app_exception.dart';
import '../../support/exceptions/storage_exception.dart';

/// Handles storage-related exceptions and logging
class StorageExceptionHandler {
  /// Handles storage exceptions with proper logging
  void handleError(AppException exception, [StackTrace? stackTrace]) {
    final logger = _getLogger();
    logger.error('Storage Error: ${exception.message}',
        error: exception,
        stackTrace: stackTrace,);

    if (exception.details != null) {
      logger.debug('Storage Error Details: ${exception.details}');
    }
  }

  /// Handles file system errors and converts them to StorageException
  StorageException handleFileSystemError(dynamic error, String operation,
      [String? path,]) {
    final message = path != null
        ? 'File system error during $operation on "$path": $error'
        : 'File system error during $operation: $error';

    return StorageException(message, error);
  }

  /// Handles disk not found errors
  StorageException handleDiskNotFound(String diskName) {
    return StorageException('Storage disk "$diskName" is not registered');
  }

  /// Handles driver not found errors
  StorageException handleDriverNotFound(String driverName) {
    return StorageException('Storage driver "$driverName" is not supported');
  }

  /// Handles configuration errors
  StorageException handleConfigError(String message, [dynamic details]) {
    return StorageException('Storage configuration error: $message', details);
  }

  /// Handles validation errors
  StorageException handleValidationError(String field, String reason) {
    return StorageException('Storage validation error for "$field": $reason');
  }

  /// Gets the logger instance (following the pattern from other systems)
  dynamic _getLogger() {
    // This would normally get Khadem.logger, but for now we'll use a simple approach
    // In the actual implementation, this would be: return Khadem.logger;
    return _SimpleLogger();
  }
}

/// Simple logger implementation for storage operations
class _SimpleLogger {
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[STORAGE ERROR] $message');
    if (error != null) print('Error: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');
  }

  void debug(String message) {
    print('[STORAGE DEBUG] $message');
  }

  void info(String message) {
    print('[STORAGE INFO] $message');
  }

  void warning(String message) {
    print('[STORAGE WARNING] $message');
  }
}
