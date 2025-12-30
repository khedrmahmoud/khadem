import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field under validation is a string.
class StringRule extends Rule {
  @override
  String get signature => 'string';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    return context.value != null && context.value is String;
  }

  @override
  String message(ValidationContext context) => 'string_validation';
}

/// Validates that the field contains only alphabetic characters.
///
/// Supports Unicode characters if [unicode] is enabled (default behavior here).
class AlphaRule extends Rule {
  @override
  String get signature => 'alpha';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return false;
    // Unicode letters
    return RegExp(r'^[\p{L}]+$', unicode: true).hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'alpha_validation';
}

/// Validates that the field contains only alphabetic characters and numbers.
class AlphaNumRule extends Rule {
  @override
  String get signature => 'alpha_num';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return false;
    // Unicode letters and numbers
    return RegExp(r'^[\p{L}\p{N}]+$', unicode: true).hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'alpha_num_validation';
}

/// Validates that the field contains only alpha-numeric characters, dashes, and underscores.
class AlphaDashRule extends Rule {
  @override
  String get signature => 'alpha_dash';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return false;
    // Unicode letters, numbers, dash and underscore
    return RegExp(r'^[\p{L}\p{N}_-]+$', unicode: true).hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'alpha_dash_validation';
}

/// Validates that the field starts with one of the given values.
class StartsWithRule extends Rule {
  @override
  String get signature => 'starts_with';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;
    if (value is! String) return false;

    final prefixes = args.map((e) => e.trim()).toList();
    return prefixes.any((prefix) => value.startsWith(prefix));
  }

  @override
  String message(ValidationContext context) => 'starts_with_validation';
}

/// Validates that the field ends with one of the given values.
class EndsWithRule extends Rule {
  @override
  String get signature => 'ends_with';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;
    if (value is! String) return false;

    final suffixes = args.map((e) => e.trim()).toList();
    return suffixes.any((suffix) => value.endsWith(suffix));
  }

  @override
  String message(ValidationContext context) => 'ends_with_validation';
}

/// Validates that the field is a strong password.
///
/// Default requirements:
/// - min 8 chars
/// - uppercase
/// - lowercase
/// - numbers
/// - symbols
class PasswordRule extends Rule {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSymbols;

  PasswordRule({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSymbols = true,
  });

  @override
  String get signature => 'password';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return false;

    if (value.length < minLength) return false;
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) return false;
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) return false;
    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) return false;
    if (requireSymbols && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;

    return true;
  }

  @override
  String message(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return 'password_validation';
    
    if (value.length < minLength) return 'password_length_validation';
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'password_uppercase_validation';
    }
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'password_lowercase_validation';
    }
    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return 'password_number_validation';
    }
    if (requireSymbols && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'password_symbol_validation';
    }

    return 'password_validation';
  }
}

/// Validates that the field is numeric and has an exact length of digits.
class DigitsRule extends Rule {
  @override
  String get signature => 'digits';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;
    
    final strVal = value.toString();
    
    final length = int.tryParse(args[0]);
    if (length == null) return false;

    // Must be numeric
    if (!RegExp(r'^[0-9]+$').hasMatch(strVal)) return false;

    return strVal.length == length;
  }

  @override
  String message(ValidationContext context) => 'digits_validation';
}

/// Validates that the field is numeric and its length is between [min] and [max].
class DigitsBetweenRule extends Rule {
  @override
  String get signature => 'digits_between';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.length < 2) return false;

    final strVal = value.toString();

    final min = int.tryParse(args[0]);
    final max = int.tryParse(args[1]);
    if (min == null || max == null) return false;

    if (!RegExp(r'^[0-9]+$').hasMatch(strVal)) return false;

    return strVal.length >= min && strVal.length <= max;
  }

  @override
  String message(ValidationContext context) => 'digits_between_validation';
}

