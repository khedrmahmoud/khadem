import '../../../support/helpers/hash_helper.dart';
import '../contracts/password_verifier.dart';

/// Hash helper implementation of PasswordVerifier
///
/// This class implements the PasswordVerifier interface using the
/// Khadem HashHelper utility. It provides secure password verification
/// and hashing operations.
class HashPasswordVerifier implements PasswordVerifier {
  @override
  Future<bool> verify(String password, String hash) async {
    return HashHelper.verify(password, hash);
  }

  @override
  Future<String> hash(String password) async {
    return HashHelper.hash(password);
  }

  @override
  bool needsRehash(String hash) {
    // Basic implementation - could be enhanced based on hash algorithm
    // For now, we'll assume rehashing is needed for very old/short hashes
    return hash.length < 60; // bcrypt hashes are typically 60 characters
  }

  /// Validates password strength
  ///
  /// [password] The password to validate
  /// Returns a map with validation results
  Map<String, dynamic> validatePasswordStrength(String password) {
    final issues = <String>[];

    if (password.length < 8) {
      issues.add('Password must be at least 8 characters long');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      issues.add('Password must contain at least one uppercase letter');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      issues.add('Password must contain at least one lowercase letter');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      issues.add('Password must contain at least one number');
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) {
      issues.add('Password must contain at least one special character');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'strength': _calculateStrength(password),
    };
  }

  /// Calculates password strength score
  ///
  /// [password] The password to evaluate
  /// Returns a strength score from 0 to 100
  int _calculateStrength(String password) {
    int score = 0;

    // Length score
    score += password.length * 2;

    // Character variety scores
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 10;
    }
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 10;
    }
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 10;
    }
    if (password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) {
      score += 15;
    }

    // Complexity bonuses
    if (password.length >= 12) {
      score += 10;
    }
    if (password.contains(
        RegExp(r'[!@#$%^&*(),.?\":{}|<>].*[!@#$%^&*(),.?\":{}|<>]'),)) {
      score += 10;
    }

    return score > 100 ? 100 : score;
  }
}
