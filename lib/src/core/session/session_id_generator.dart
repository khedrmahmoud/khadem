import 'dart:convert';
import 'dart:math';

/// Session ID Generator
/// Single responsibility: Generate cryptographically secure session IDs
class SessionIdGenerator {
  /// Generates a cryptographically secure session ID with 256-bit entropy
  /// Returns a Base64 URL-safe string
  String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', ''); // 256-bit Base64 secure string
  }
}
