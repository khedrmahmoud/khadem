import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field under validation is present and not empty.
///
/// Checks for null, empty strings (after trim), empty lists, and empty maps.
///
/// Signature: `required`
///
/// Examples:
/// - `required`
class RequiredRule extends Rule {
  @override
  String get signature => 'required';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;

    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;

    return true;
  }

  @override
  String message(ValidationContext context) => 'required_validation';
}
