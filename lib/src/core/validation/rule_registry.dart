import '../../contracts/validation/rule.dart';
import '../../support/validation_rules/rules.dart';

class ValidationRuleRepository {
  static final Map<String, Rule Function()> _rules = {
    // Basic validation rules
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

    // String validation rules
    'string': () => StringRule(),
    'alpha': () => AlphaRule(),
    'alpha_num': () => AlphaNumRule(),
    'alpha_dash': () => AlphaDashRule(),
    'starts_with': () => StartsWithRule(),
    'ends_with': () => EndsWithRule(),

    // File validation rules
    'file': () => FileRule(),
    'image': () => ImageRule(),
    'mimes': () => MimesRule(),
    'max_file_size': () => MaxFileSizeRule(),

    // Date validation rules
    'date': () => DateRule(),
    'date_format': () => DateFormatRule(),
    'before': () => BeforeRule(),
    'after': () => AfterRule(),

    // Network validation rules
    'url': () => UrlRule(),
    'active_url': () => ActiveUrlRule(),
    'ip': () => IpRule(),
    'ipv4': () => Ipv4Rule(),
    'ipv6': () => Ipv6Rule(),

    // Array validation rules
    'array': () => ArrayRule(),
    'distinct': () => DistinctRule(),
    'min_items': () => MinItemsRule(),
    'max_items': () => MaxItemsRule(),
    'in_array': () => InArrayRule(),
    'not_in_array': () => NotInArrayRule(),

    // Miscellaneous validation rules
    'uuid': () => UuidRule(),
    'json': () => JsonRule(),
    'phone': () => PhoneRule(),
    'nullable': () => NullableRule(),
    'sometimes': () => SometimesRule(),
    'prohibited': () => ProhibitedRule(),
    'prohibited_if': () => ProhibitedIfRule(),
    'required_if': () => RequiredIfRule(),
  };

  static Rule? resolve(String name) {
    final factory = _rules[name];
    return factory != null ? factory() : null;
  }

  static void register(String name, Rule Function() factory) {
    _rules[name] = factory;
  }
  static void registerAll(Map<String, Rule Function()> rules) {
    _rules.addAll(rules);
  }

  static void unregister(String name) {
    _rules.remove(name);
  }

  static List<String> get registeredRules => _rules.keys.toList();

  static int get ruleCount => _rules.length;
}
