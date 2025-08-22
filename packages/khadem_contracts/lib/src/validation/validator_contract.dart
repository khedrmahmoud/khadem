/// Validation contract that defines the required methods for data validation
abstract class ValidatorContract {
  /// Validate data against rules
  Map<String, List<String>> validate(
    Map<String, dynamic> data,
    Map<String, List<String>> rules,
  );

  /// Add a custom validation rule
  void addRule(String name, bool Function(dynamic value, Map<String, dynamic> data) rule);

  /// Check if validation passes
  bool passes();

  /// Get validation errors
  Map<String, List<String>> errors();

  /// Add a validation error
  void addError(String field, String message);

  /// Get first error for a field
  String? firstError(String field);

  /// Get all errors for a field
  List<String> getFieldErrors(String field);
}
