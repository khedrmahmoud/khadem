import 'dart:math';
import 'package:crypto/crypto.dart';

/// Session ID Generator
/// Single responsibility: Generate cryptographically secure session IDs
class SessionIdGenerator {
  /// Generates a cryptographically secure session ID
  String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 32);
  }
}