import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is a valid credit card number using the Luhn algorithm.
///
/// Signature: `credit_card`
///
/// Examples:
/// - `credit_card`
class CreditCardRule extends Rule {
  @override
  String get signature => 'credit_card';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return false;

    // Remove all non-digits
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return false;

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int n = int.parse(clean[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }

  @override
  String message(ValidationContext context) => 'credit_card_validation';
}
