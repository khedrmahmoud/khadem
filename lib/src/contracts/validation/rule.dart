/// Base class for creating validation rules.
///
/// Each rule must implement a [validate] method that returns a string error message,
/// or `null` if the value is valid.
abstract class Rule {
  /// Validates the [value] of the given [field] using optional [arg].
  ///
  /// Returns `null` if valid, otherwise returns a string error message.
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  });
}
