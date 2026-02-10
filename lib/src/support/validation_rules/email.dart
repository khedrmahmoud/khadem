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

    // Basic email regex, could be improved or use a library
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'email_validation';
}
