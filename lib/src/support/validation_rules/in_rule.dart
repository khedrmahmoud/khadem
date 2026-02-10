import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is contained in the given list of values.
///
/// Signature: `in:val1,val2,...`
///
/// Examples:
/// - `in:admin,user`
/// - `in:pending,approved,rejected`
class InRule extends Rule implements RuleMessageParametersProvider {
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

  @override
  Map<String, dynamic> messageParameters(ValidationContext context) {
    final options =
        _values?.map((e) => e.toString()).toList() ?? context.parameters;
    return {
      'values': options.join(', '),
    };
  }
}
