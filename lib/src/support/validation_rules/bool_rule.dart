import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field under validation is a boolean.
///
/// Accepts `true`, `false`, `1`, `0`, "true", "false", "1", "0".
class BoolRule extends Rule {
  @override
  String get signature => 'bool';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value is bool) return true;
    if (value is num) return value == 0 || value == 1;
    if (value is String) {
        final lower = value.toLowerCase();
        return ['true', 'false', '1', '0'].contains(lower);
    }
    return false;
  }

  @override
  String message(ValidationContext context) => 'bool_validation';
}
