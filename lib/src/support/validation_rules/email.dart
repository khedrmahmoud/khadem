import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is a valid email address.
///
/// Signature: `email`
///
/// Examples:
/// - `email`
class EmailRule extends Rule {
  @override
  String get signature => 'email';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) {
      return false;
    }

    return _isValidEmail(value.trim());
  }

  bool _isValidEmail(String value) {
    if (value.isEmpty || value.length > 254) {
      return false;
    }

    final atIndex = value.indexOf('@');
    if (atIndex <= 0 || atIndex != value.lastIndexOf('@')) {
      return false;
    }

    final local = value.substring(0, atIndex);
    final domain = value.substring(atIndex + 1);

    if (local.isEmpty || domain.isEmpty) {
      return false;
    }

    if (local.length > 64 || domain.length > 253) {
      return false;
    }

    if (local.startsWith('.') || local.endsWith('.') || local.contains('..')) {
      return false;
    }

    if (!_isValidLocalPart(local)) {
      return false;
    }

    return _isValidDomain(domain);
  }

  bool _isValidLocalPart(String local) {
    for (final unit in local.codeUnits) {
      final isAlphaNum =
          (unit >= 48 && unit <= 57) ||
          (unit >= 65 && unit <= 90) ||
          (unit >= 97 && unit <= 122);
      const allowedSymbols = {46, 95, 37, 43, 45}; // . _ % + -

      if (!isAlphaNum && !allowedSymbols.contains(unit)) {
        return false;
      }
    }

    return true;
  }

  bool _isValidDomain(String domain) {
    if (domain.startsWith('.') ||
        domain.endsWith('.') ||
        domain.contains('..')) {
      return false;
    }

    final labels = domain.split('.');
    if (labels.length < 2) {
      return false;
    }

    for (final label in labels) {
      if (label.isEmpty || label.length > 63) {
        return false;
      }

      if (label.startsWith('-') || label.endsWith('-')) {
        return false;
      }

      for (final unit in label.codeUnits) {
        final isAlphaNum =
            (unit >= 48 && unit <= 57) ||
            (unit >= 65 && unit <= 90) ||
            (unit >= 97 && unit <= 122);
        if (!isAlphaNum && unit != 45) {
          return false;
        }
      }
    }

    final tld = labels.last;
    if (tld.length < 2) {
      return false;
    }

    for (final unit in tld.codeUnits) {
      final isLetter =
          (unit >= 65 && unit <= 90) || (unit >= 97 && unit <= 122);
      if (!isLetter) {
        return false;
      }
    }

    return true;
  }

  @override
  String message(ValidationContext context) => 'email_validation';
}
