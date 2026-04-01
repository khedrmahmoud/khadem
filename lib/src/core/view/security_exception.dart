/// Security-related exceptions for the view system
class SecurityException implements Exception {
  final String message;

  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
