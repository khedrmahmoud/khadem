import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field matches the given regex pattern.
class RegexRule extends Rule {
  final String? _pattern;
  RegexRule([this._pattern]);

  @override
  String get signature => 'regex';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final args = context.parameters;
    final value = context.value;
    final pattern = _pattern ?? (args.isNotEmpty ? args[0] : null);
    if (pattern == null) return true;
    final regex = RegExp(pattern);
    return value is String && regex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'regex_validation';
}
