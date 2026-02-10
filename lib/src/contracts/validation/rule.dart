import 'dart:async';

/// Context object containing all information needed for validation.
class ValidationContext {
  /// The name of the field being validated.
  final String attribute;

  /// The value being validated.
  final dynamic value;

  /// The arguments passed to the validation rule (e.g. min:5 -> ['5']).
  final List<String> parameters;

  /// The full data object being validated.
  final Map<String, dynamic> data;

  ValidationContext({
    required this.attribute,
    required this.value,
    required this.data,
    this.parameters = const [],
  });
}

/// Base class for creating validation rules.
///
/// Each rule must implement a [validate] method that returns true if valid,
/// or false if invalid.
abstract class Rule {
  /// The error message to be returned if validation fails.
  /// Can be overridden by the user.
  String? customMessage;

  /// Returns the unique signature of the rule.
  /// Defaults to the class name in snake_case (logic handled by registry usually, but good to have).
  String get signature;

  /// Validates the value using the given [context].
  ///
  /// Returns `true` if valid, otherwise `false`.
  FutureOr<bool> passes(ValidationContext context);

  /// Returns the validation error message.
  String message(ValidationContext context);
}

/// Optional contract for rules that want to provide extra localization
/// parameters for their error messages.
///
/// Example: the `in` rule can provide a `values` parameter used by
/// translations like `Allowed values: :values`.
abstract interface class RuleMessageParametersProvider {
  Map<String, dynamic> messageParameters(ValidationContext context);
}

/// Wrapper type to indicate that a message parameter is a reference
/// to another field name.
///
/// The validator can then localize it using the fields translation file.
class FieldName {
  final String name;

  const FieldName(this.name);

  @override
  String toString() => name;
}
