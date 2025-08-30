import '../../support/exceptions/validation_exception.dart';
import '../lang/lang.dart';
import 'rule_registry.dart';

class Validator {
  final Map<String, dynamic> data;
  final Map<String, String> rules;
  final Map<String, String> errors = {};

  Validator(this.data, this.rules);

  bool passes() {
    for (final entry in rules.entries) {
      final field = entry.key;
      final ruleString = entry.value;
      final value = data[field];
      final ruleParts = ruleString.split('|');

      for (final part in ruleParts) {
        final segments = part.split(':');
        final name = segments[0];
        final arg = segments.length > 1 ? segments[1] : null;

        final rule = RuleRegistry.resolve(name);
        if (rule != null) {
          final messageKey = rule.validate(field, value, arg, data: data);
          if (messageKey != null) {
             errors[field] = Lang.t(messageKey, parameters: {'field': field, 'arg': arg});
            break;
          }
        }
      }
    }

    return errors.isEmpty;
  }

  void validate() {
    if (!passes()) {
      throw ValidationException(errors);
    }
  }
}
