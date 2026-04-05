import 'dart:async';
import 'dart:isolate';
import '../../contracts/validation/rule.dart';

/// Validates that the field matches the given regex pattern.
///
/// Signature: `regex:pattern`
///
/// Examples:
/// - `regex:^\d+$`
/// - `regex:^[A-Z]{3}-\d{4}$`
class RegexRule extends Rule {
  final String? _pattern;
  RegexRule([this._pattern]);

  @override
  String get signature => 'regex';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final args = context.parameters;
    final value = context.value;
    final pattern = _pattern ?? (args.isNotEmpty ? args.join(',') : null);
    if (pattern == null) return true;
    if (value is! String) return false;

    try {
      return await Isolate.run(() {
        final regex = RegExp(pattern);
        return regex.hasMatch(value);
      }).timeout(const Duration(milliseconds: 150));
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'regex_validation';
}
