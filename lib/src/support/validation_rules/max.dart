import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is at most [max].
///
/// Behavior depends on type:
/// - Numeric: value <= max
/// - String: length <= max
/// - Collection: length <= max
class MaxRule extends Rule {
  final num? _max;
  MaxRule([this._max]);

  @override
  String get signature => 'max';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    final max = _max ?? num.tryParse(args.isNotEmpty ? args[0] : '') ?? 9999;

    if (value == null) return true;

    if (value is num) {
      return value <= max;
    } else if (value is String) {
      return value.length <= max;
    } else if (value is Iterable || value is Map) {
      return value.length <= max;
    } else {
      return value.toString().length <= max;
    }
  }

  @override
  String message(ValidationContext context) {
    final value = context.value;
    if (value is num) {
      return 'max_value_validation';
    }
    return 'max_validation';
  }
}
