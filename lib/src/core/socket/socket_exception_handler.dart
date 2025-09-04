
import 'package:khadem/khadem_dart.dart';


/// Handles exceptions in socket operations and sends appropriate error responses.
class SocketExceptionHandler {
  /// Handle socket exception and send error response to client
  static void handle(
    SocketClient client,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    try {
      // Log the error
      Khadem.logger.error('❌ Socket error for client ${client.id}: $error');
      if (stackTrace != null) {
        Khadem.logger.debug('Stack trace: $stackTrace');
      }

      // Send error response to client
      final errorResponse = _formatErrorResponse(error, stackTrace);
      client.send('error', errorResponse);
    } catch (e) {
      // If error handling itself fails, log it and send a generic error
      Khadem.logger.error('❌ Failed to handle socket error: $e');
      try {
        client.send('error', {
          'message': 'Internal server error',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Last resort - just log the error
        Khadem.logger.error('❌ Could not send error response to client ${client.id}');
      }
    }
  }

  /// Handle socket exception without sending response (for cleanup operations)
  static void handleSilently(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    Khadem.logger.error('❌ Socket error: $error');
    if (stackTrace != null) {
      Khadem.logger.debug('Stack trace: $stackTrace');
    }
  }

  /// Format error response for client
  static Map<String, dynamic> _formatErrorResponse(
    Object error,
    StackTrace? stackTrace,
  ) {
    final response = <String, dynamic>{
      'error': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // In development, include more details
    final isDevelopment = Khadem.isDevelopment;
    if (isDevelopment) {
      response['message'] = error is AppException ? error.message : error.toString();
      response['type'] = error.runtimeType.toString();
      if (stackTrace != null) {
        response['stack_trace'] = stackTrace.toString();
      }
    } else {
      // In production, use generic message
      response['message'] = 'An error occurred while processing your request';
    }

    return response;
  }

  /// Handle client disconnection errors
  static void handleDisconnectError(
    SocketClient client,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    Khadem.logger.warning('⚠️ Client ${client.id} disconnected with error: $error');
    if (stackTrace != null) {
      Khadem.logger.debug('Disconnect stack trace: $stackTrace');
    }
  }

  /// Handle middleware execution errors
  static void handleMiddlewareError(
    SocketClient client,
    Object error,
    StackTrace? stackTrace,
    String middlewareName,
  ) {
    Khadem.logger.error('❌ Middleware "$middlewareName" failed for client ${client.id}: $error');
    if (stackTrace != null) {
      Khadem.logger.debug('Middleware stack trace: $stackTrace');
    }
    if (error is AppException) {
      handle(client, error, stackTrace);
    } else {
      handle(client, 'Middleware execution failed', stackTrace);
    }
  }
}
