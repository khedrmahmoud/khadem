import '../../contracts/validation/rule.dart';
import '../../support/validation_rules/rules.dart';

class RuleRegistry {
  static final Map<String, Rule Function()> _rules = {
    'required': () => RequiredRule(),
    'email': () => EmailRule(),
    'min': () => MinRule(),
    'max': () => MaxRule(),
    'int': () => IntRule(),
    'bool': () => BoolRule(),
    'in': () => InRule(),
    'numeric': () => NumericRule(),
    'regex': () => RegexRule(),
    'confirmed': () => ConfirmedRule(),
  };

  static Rule? resolve(String name) {
    final factory = _rules[name];
    return factory != null ? factory() : null;
  }

  static void register(String name, Rule Function() factory) {
    _rules[name] = factory;
  }
}
