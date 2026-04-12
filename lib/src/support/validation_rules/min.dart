import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is at least [min].
///
/// Behavior depends on type:
/// - Numeric: value >= min
/// - String: length >= min
/// - Collection: length >= min
///
/// Signature: `min:value`
///
/// Examples:
/// - `min:18`
/// - `min:3`
class MinRule extends Rule implements RuleMessageParametersProvider {
  final num? _min;
  MinRule([this._min]);

  @override
  String get signature => 'min';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    final min = _min ?? num.tryParse(args.isNotEmpty ? args[0] : '') ?? 0;

    if (value == null) return true; // Null rules usually handled by 'required'

    if (value is num) {
      return value >= min;
    } else if (value is String) {
      // Check if string is numeric and we strictly want numeric comparison ??
      // Laravel heuristic: if 'numeric' rule is present, treat as number.
      // Here we assume String -> Length, unless it looks like a number?
      // Standard is: String -> Length. Numeric -> Value.
      // But if input is from HTTP form, it's always string.
      // Better approach: context.isNumeric?
      // For now, adhere to simple type check: String -> Length.
      // UNLESS the user explicitly casts it or we check 'numeric' rule presence (hard here).
      // Let's stick to standard behavior: String=length.
      return value.length >= min;
    } else if (value is Iterable || value is Map) {
      return value.length >= min;
    } else {
      return value.toString().length >= min;
    }
  }

  @override
  String message(ValidationContext context) {
    final value = context.value;
    if (value is num) {
      return 'min_value_validation';
    }
    return 'min_validation';
  }

  @override
  Map<String, dynamic> messageParameters(ValidationContext context) {
    final args = context.parameters;
    final min = _min ?? num.tryParse(args.isNotEmpty ? args[0] : '') ?? 0;
    return {'min': min};
  }
}
