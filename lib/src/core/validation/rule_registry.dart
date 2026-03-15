import 'package:khadem/contracts.dart' show Rule;
import 'package:khadem/src/support/validation_rules/rules.dart';

class ValidationRuleRepository {
  static final _rules = <String, Rule>{
    // Basic validation rules
    'required': RequiredRule(),
    'email': EmailRule(),
    'min': MinRule(),
    'max': MaxRule(),
    'int': IntRule(),
    'bool': BoolRule(),
    'in': InRule(),
    'numeric': NumericRule(),
    'regex': RegexRule(),
    'confirmed': ConfirmedRule(),

    // String validation rules
    'string': StringRule(),
    'alpha': AlphaRule(),
    'alpha_num': AlphaNumRule(),
    'alpha_dash': AlphaDashRule(),
    'starts_with': StartsWithRule(),
    'ends_with': EndsWithRule(),
    'password': PasswordRule(),
    'digits': DigitsRule(),
    'digits_between': DigitsBetweenRule(),

    // File validation rules
    'file': FileRule(),
    'image': ImageRule(),
    'mimes': MimesRule(),
    'max_file_size': MaxFileSizeRule(),
    'min_file_size': MinFileSizeRule(),

    // Date validation rules
    'date': DateRule(),
    'date_format': DateFormatRule(),
    'before': BeforeRule(),
    'after': AfterRule(),

    // Network validation rules
    'url': UrlRule(),
    'active_url': ActiveUrlRule(),
    'ip': IpRule(),
    'ipv4': Ipv4Rule(),
    'ipv6': Ipv6Rule(),
    'mac_address': MacAddressRule(),

    // Array validation rules
    'array': ArrayRule(),
    'list': ListRule(),
    'map': MapRule(),
    'distinct': DistinctRule(),
    'min_items': MinItemsRule(),
    'max_items': MaxItemsRule(),
    'in_array': InArrayRule(),
    'not_in_array': NotInArrayRule(),
    'subset': SubsetRule(),

    // Miscellaneous validation rules
    'uuid': UuidRule(),
    'json': JsonRule(),
    'phone': PhoneRule(),
    'nullable': NullableRule(),
    'sometimes': SometimesRule(),
    'prohibited': ProhibitedRule(),
    'prohibited_if': ProhibitedIfRule(),
    'required_if': RequiredIfRule(),
    'different': DifferentRule(),
    'same': SameRule(),
    'accepted': AcceptedRule(),
    'credit_card': CreditCardRule(),

    // database-related validation rules
    'unique': UniqueRule(),
    'exists': ExistsRule(),
  };

  static Rule? resolve(String name) {
    return _rules[name];
  }

  static void register(String name, Rule rule) {
    _rules[name] = rule;
  }

  static void registerAll(Map<String, Rule> rules) {
    _rules.addAll(rules);
  }

  static void unregister(String name) {
    _rules.remove(name);
  }

  static List<String> get registeredRules => _rules.keys.toList();

  static int get ruleCount => _rules.length;
}
