import 'dart:async';
import 'dart:convert';
import '../../contracts/validation/rule.dart';

/// Validates that a value is a valid UUID (Universal Unique Identifier).
///
/// Supports UUID versions 1, 3, 4, and 5.
/// Matches strict RFC 4122 format.
///
/// Signature: `uuid`
///
/// Examples:
/// - `uuid`
class UuidRule extends Rule {
  @override
  String get signature => 'uuid';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

    // Strict regex for UUID v1-v5
    // xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx
    // M is version (1-5), N is variant (8, 9, a, b)
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      caseSensitive: false,
    );

    return uuidRegex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'uuid_validation';
}

/// Validates that a value is a valid JSON string.
///
/// Uses [jsonDecode] to verify the string structure.
///
/// Signature: `json`
///
/// Examples:
/// - `json`
class JsonRule extends Rule {
  @override
  String get signature => 'json';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

    try {
      jsonDecode(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'json_validation';
}

/// Validates that a value is a valid phone number.
///
/// Checks against E.164 standard format (up to 15 digits).
/// Allows optional leading `+` and sanitized separators like spaces, dashes, and parentheses.
///
/// Signature: `phone`
///
/// Examples:
/// - `phone`
class PhoneRule extends Rule {
  @override
  String get signature => 'phone';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

    // E.164 compliant (ish) + optional spaces/dashes
    final phoneRegex = RegExp(
      r'^\+?[1-9]\d{1,14}$',
    );
    // Sanitize
    final sanitized = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return phoneRegex.hasMatch(sanitized);
  }

  @override
  String message(ValidationContext context) => 'phone_validation';
}

/// Indicates that the field under validation may be null.
///
/// This rule is a marker for the validator to skip other rules if the value is null.
/// It always passes validation itself.
///
/// Signature: `nullable`
///
/// Examples:
/// - `nullable`
class NullableRule extends Rule {
  @override
  String get signature => 'nullable';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    // Nullable rule always passes validation.
    return true;
  }

  @override
  String message(ValidationContext context) => '';
}

/// Indicates that the field under validation is optional and may not be present in the input data.
///
/// If the field is present, it will be validated against other rules.
/// If absent, other rules are skipped.
///
/// Signature: `sometimes`
///
/// Examples:
/// - `sometimes`
class SometimesRule extends Rule {
  @override
  String get signature => 'sometimes';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    return true;
  }

  @override
  String message(ValidationContext context) => '';
}

/// Validates that the field must be missing or empty.
///
/// Fails if the field is present and not empty (not null, not empty string, not empty list/map).
///
/// Signature: `prohibited`
///
/// Examples:
/// - `prohibited`
class ProhibitedRule extends Rule {
  @override
  String get signature => 'prohibited';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;

    // If null, it's considered empty/missing -> Pass
    if (value == null) return true;

    // If string and empty -> Pass
    if (value is String && value.trim().isEmpty) return true;

    // If collection and empty -> Pass
    if (value is Iterable && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;

    // Otherwise, it is present and not empty -> Fail
    return false;
  }

  @override
  String message(ValidationContext context) => 'prohibited_validation';
}

/// Validates that the field must be missing or empty if another field is equal to a value.
///
/// Signature: `prohibited_if:otherField,value`
///
/// Examples:
/// - `prohibited_if:is_admin,true`
class ProhibitedIfRule extends Rule implements RuleMessageParametersProvider {
  @override
  String get signature => 'prohibited_if';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final args = context.parameters;
    final data = context.data;
    if (args.length < 2) return true;

    final otherField = args[0];
    final expectedValue = args[1];

    // Check if condition is met
    if (data.containsKey(otherField) &&
        data[otherField].toString() == expectedValue) {
      // If condition meets, field must be prohibited (empty/missing)
      // Re-use logic from ProhibitedRule
      final value = context.value;
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      if (value is Iterable && value.isEmpty) return true;
      if (value is Map && value.isEmpty) return true;

      return false;
    }
    return true;
  }

  @override
  String message(ValidationContext context) => 'prohibited_if_validation';

  @override
  Map<String, dynamic> messageParameters(ValidationContext context) {
    final args = context.parameters;
    if (args.length < 2) return const {};

    return {
      'other': FieldName(args[0]),
      'value': args[1],
    };
  }
}

/// Validates that the field is required if another field is equal to a value.
///
/// Signature: `required_if:otherField,value`
///
/// Examples:
/// - `required_if:country,EG`
class RequiredIfRule extends Rule implements RuleMessageParametersProvider {
  @override
  String get signature => 'required_if';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final args = context.parameters;
    final data = context.data;
    final value = context.value;

    if (args.length < 2) return true;

    final otherField = args[0];
    final expectedValue = args[1];

    if (data.containsKey(otherField) &&
        data[otherField].toString() == expectedValue) {
      // Condition met, so it IS required
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
      if (value is Iterable && value.isEmpty) return false;
      if (value is Map && value.isEmpty) return false;
    }
    return true;
  }

  @override
  String message(ValidationContext context) => 'required_if_validation';

  @override
  Map<String, dynamic> messageParameters(ValidationContext context) {
    final args = context.parameters;
    if (args.length < 2) return const {};

    return {
      'other': FieldName(args[0]),
      'value': args[1],
    };
  }
}
