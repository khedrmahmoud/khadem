import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field matches the value of `{field}_confirmation`.
///
/// Signature: `confirmed`
///
/// Examples:
/// - `confirmed`
class ConfirmedRule extends Rule {
  @override
  String get signature => 'confirmed';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final field = context.attribute;
    final value = context.value;
    final data = context.data;
    final confirmation = data['${field}_confirmation'];
    return value == confirmation;
  }

  @override
  String message(ValidationContext context) => 'confirmed_validation';
}
