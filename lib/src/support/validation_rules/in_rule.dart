import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is contained in the given list of values.
class InRule extends Rule {
  final List<dynamic>? _values;
  InRule([this._values]);

  @override
  String get signature => 'in';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;

    final args = context.parameters;
    final options = _values?.map((e) => e.toString()).toList() ?? args;
    
    return options.contains(value.toString());
  }

  @override
  String message(ValidationContext context) => 'in_validation';
}
