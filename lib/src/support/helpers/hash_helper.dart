import 'dart:convert';

import 'package:crypto/crypto.dart';

class HashHelper {
  /// Hashes the password using SHA-256 (replace with bcrypt if needed)
  static String hash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies the password by comparing raw input with hashed version
  static bool verify(String raw, String hashed) {
    return hash(raw) == hashed;
  }
}
