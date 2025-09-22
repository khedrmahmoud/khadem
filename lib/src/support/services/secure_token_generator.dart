import 'dart:convert';
import 'dart:math';

import '../../modules/auth/contracts/token_generator.dart';

/// Secure token generator implementation
///
/// This class provides secure token generation using cryptographically
/// secure random number generation. It implements various token formats
/// and validation methods.
class SecureTokenGenerator implements TokenGenerator {
  /// Secure random number generator
  static final Random _random = Random.secure();

  /// Characters used for token generation
  static const String _tokenChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  @override
  String generateToken({int length = 64, String? prefix}) {
    final tokenPart = _generateSecureString(length);
    return prefix != null ? '$prefix|$tokenPart' : tokenPart;
  }

  @override
  String generateRefreshToken({int length = 64}) {
    return _generateSecureString(length);
  }

  @override
  bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;

    // Check for basic token format (alphanumeric + - and _)
    final basicPattern = RegExp(r'^[A-Za-z0-9\-_]+$');

    // Check for prefixed token format (prefix|token)
    final prefixedPattern = RegExp(r'^[A-Za-z0-9\-_]+\|[A-Za-z0-9\-_]+$');

    return basicPattern.hasMatch(token) || prefixedPattern.hasMatch(token);
  }

  /// Generates a secure random string
  ///
  /// [length] The desired string length
  /// Returns a base64 URL-safe encoded string
  String _generateSecureString(int length) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).substring(0, length);
  }

  /// Generates a numeric token
  ///
  /// [length] The desired token length
  /// Returns a numeric token string
  String generateNumericToken({int length = 6}) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }

  /// Generates an alphanumeric token
  ///
  /// [length] The desired token length
  /// Returns an alphanumeric token string
  String generateAlphanumericToken({int length = 32}) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_tokenChars[_random.nextInt(_tokenChars.length)]);
    }
    return buffer.toString();
  }

  /// Generates a UUID-like token
  ///
  /// Returns a UUID-like token string
  String generateUuidToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version (4) and variant bits according to RFC 4122
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant bits

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
