import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field under validation is an integer.
///
/// Signature: `int`
///
/// Examples:
/// - `int`
class IntRule extends Rule {
  @override
  String get signature => 'int';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is int) return true;
    if (value is String && int.tryParse(value) != null) return true;
    return false;
  }

  @override
  String message(ValidationContext context) => 'int_validation';
}
