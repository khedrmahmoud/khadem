import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is different from another field.
class DifferentRule extends Rule {
  @override
  String get signature => 'different';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final args = context.parameters;
    final data = context.data;
    if (args.isEmpty) return false;

    final otherField = args[0];
    if (!data.containsKey(otherField)) {
       // If other field is missing, strictly it relies on how we define "different".
       // Laravel: "The given field must be different than the field under validation."
       // If other field is null/missing, and this field is not null, they are different.
       return true;
    }

    final otherValue = data[otherField];
    final value = context.value;

    return value != otherValue;
  }

  @override
  String message(ValidationContext context) => 'different_validation';
}

/// Validates that the field is the same as another field.
class SameRule extends Rule {
  @override
  String get signature => 'same';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final args = context.parameters;
    final data = context.data;
    if (args.isEmpty) return false;

    final otherField = args[0];
    final otherValue = data[otherField]; // null if missing
    final value = context.value;

    return value == otherValue;
  }

  @override
  String message(ValidationContext context) => 'same_validation';
}

/// Validates that the field is "accepted".
///
/// checks for: 'yes', 'on', '1', 1, true, 'true'.
class AcceptedRule extends Rule {
  @override
  String get signature => 'accepted';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    
    final acceptedValues = ['yes', 'on', '1', 1, true, 'true'];
    if (value is String) {
      return acceptedValues.contains(value.toLowerCase());
    }
    return acceptedValues.contains(value);
  }

  @override
  String message(ValidationContext context) => 'accepted_validation';
}
