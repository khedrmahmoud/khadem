import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field under validation is numeric.
class NumericRule extends Rule {
  @override
  String get signature => 'numeric';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is num) return true;
    if (value is String && num.tryParse(value) != null) return true;
    return false;
  }

  @override
  String message(ValidationContext context) => 'numeric_validation';
}
