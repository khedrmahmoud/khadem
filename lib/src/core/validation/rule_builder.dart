import '../../support/validation_rules/array_rules.dart';
import '../../support/validation_rules/bool_rule.dart';
import '../../support/validation_rules/confirmed.dart';
import '../../support/validation_rules/database_rules.dart';
import '../../support/validation_rules/date_rules.dart';
import '../../support/validation_rules/email.dart';
import '../../support/validation_rules/file_rules.dart';
import '../../support/validation_rules/in_rule.dart';
import '../../support/validation_rules/int_rule.dart';
import '../../support/validation_rules/max.dart';
import '../../support/validation_rules/min.dart';
import '../../support/validation_rules/network_rules.dart';
import '../../support/validation_rules/numeric.dart';
import '../../support/validation_rules/regex.dart';
import '../../support/validation_rules/required.dart';
import '../../support/validation_rules/string_rules.dart';

/// A fluent builder for validation rules.
class RuleBuilder {
  final List<dynamic> _rules = [];

  /// Creates a new RuleBuilder.
  RuleBuilder();

  /// Adds a raw rule (String or Rule object).
  RuleBuilder add(dynamic rule) {
    _rules.add(rule);
    return this;
  }

  /// Builds the list of rules.
  List<dynamic> build() => _rules;

  // --- Common Rules ---

  RuleBuilder required() {
    _rules.add(RequiredRule());
    return this;
  }

  RuleBuilder nullable() {
    _rules.add('nullable');
    return this;
  }

  RuleBuilder bail() {
    _rules.add('bail');
    return this;
  }

  // --- String Rules ---

  RuleBuilder string() {
    _rules.add(StringRule());
    return this;
  }

  RuleBuilder email() {
    _rules.add(EmailRule());
    return this;
  }

  RuleBuilder alpha() {
    _rules.add(AlphaRule());
    return this;
  }

  RuleBuilder alphaNum() {
    _rules.add(AlphaNumRule());
    return this;
  }

  RuleBuilder regex(String pattern) {
    _rules.add(RegexRule(pattern));
    return this;
  }

  RuleBuilder url() {
    _rules.add(UrlRule());
    return this;
  }

  // --- Numeric Rules ---

  RuleBuilder numeric() {
    _rules.add(NumericRule());
    return this;
  }

  RuleBuilder integer() {
    _rules.add(IntRule());
    return this;
  }

  RuleBuilder min(num value) {
    _rules.add(MinRule(value));
    return this;
  }

  RuleBuilder max(num value) {
    _rules.add(MaxRule(value));
    return this;
  }

  // --- Array/Collection Rules ---

  RuleBuilder array() {
    _rules.add(ArrayRule());
    return this;
  }

  RuleBuilder inList(List<dynamic> values) {
    _rules.add(InRule(values));
    return this;
  }

  // --- File Rules ---

  RuleBuilder file() {
    _rules.add(FileRule());
    return this;
  }

  RuleBuilder image() {
    _rules.add(ImageRule());
    return this;
  }

  RuleBuilder mimes(List<String> types) {
    _rules.add(MimesRule(types));
    return this;
  }

  // --- Database Rules ---

  RuleBuilder unique(String table,
      {String? column, dynamic ignoreId, String ignoreColumn = 'id',}) {
    _rules.add(UniqueRule(table, column, ignoreId, ignoreColumn));
    return this;
  }

  RuleBuilder exists(String table, {String? column}) {
    _rules.add(ExistsRule(table, column));
    return this;
  }

  // --- Other Rules ---

  RuleBuilder boolean() {
    _rules.add(BoolRule());
    return this;
  }

  RuleBuilder date() {
    _rules.add(DateRule());
    return this;
  }

  RuleBuilder confirmed() {
    _rules.add(ConfirmedRule());
    return this;
  }

  RuleBuilder password({
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSymbols = true,
  }) {
    _rules.add(
      PasswordRule(
        minLength: minLength,
        requireUppercase: requireUppercase,
        requireLowercase: requireLowercase,
        requireNumbers: requireNumbers,
        requireSymbols: requireSymbols,
      ),
    );
    return this;
  }
}
