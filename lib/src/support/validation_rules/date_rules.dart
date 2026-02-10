import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field is a valid date string.
///
/// Uses [DateTime.parse] to validate ISO-8601 formatted dates.
///
/// Signature: `date`
///
/// Examples:
/// - `date`
class DateRule extends Rule {
  @override
  String get signature => 'date';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

    try {
      DateTime.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'date_validation';
}

/// Validates that the field matches the given date format.
///
/// Supports basic formats like `Y-m-d` (YYYY-MM-DD).
/// For other formats, it falls back to standard [DateTime.parse].
///
/// Signature: `date_format:format`
///
/// Examples:
/// - `date_format:Y-m-d`
class DateFormatRule extends Rule {
  @override
  String get signature => 'date_format';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;
    if (value is! String) return false;

    try {
      final format = args[0];
      if (format == 'Y-m-d' || format == 'Y/m/d') {
        final dateRegex = RegExp(r'^\d{4}[-/]\d{2}[-/]\d{2}$');
        if (!dateRegex.hasMatch(value)) return false;

        final parts = value.split(RegExp(r'[-/]'));
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        final date = DateTime(year, month, day);
        return date.year == year && date.month == month && date.day == day;
      } else {
        DateTime.parse(value);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'date_format_validation';
}

/// Validates that the date is before a given date.
///
/// checks against:
/// - 'today', 'tomorrow', 'yesterday'
/// - another field in the data
/// - a specific date string
///
/// Signature: `before:dateOrField`
///
/// Examples:
/// - `before:today`
/// - `before:start_date`
class BeforeRule extends Rule {
  @override
  String get signature => 'before';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    final data = context.data;
    if (value == null) return false;
    if (value is! String) return false;

    try {
      final valueDate = DateTime.parse(value);
      DateTime compareDate;
      final arg = args.isNotEmpty ? args[0] : null;

      if (arg == 'today') {
        compareDate = DateTime.now();
      } else if (arg == 'tomorrow') {
        compareDate = DateTime.now().add(const Duration(days: 1));
      } else if (arg == 'yesterday') {
        compareDate = DateTime.now().subtract(const Duration(days: 1));
      } else if (arg != null && data.containsKey(arg)) {
        final otherValue = data[arg];
        if (otherValue is String) {
          compareDate = DateTime.parse(otherValue);
        } else {
          return false;
        }
      } else if (arg != null) {
        compareDate = DateTime.parse(arg);
      } else {
        return false;
      }

      return valueDate.isBefore(compareDate);
    } catch (e) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'before_validation';
}

/// Validates that the date is after a given date.
///
/// checks against:
/// - 'today', 'tomorrow', 'yesterday'
/// - another field in the data
/// - a specific date string
///
/// Signature: `after:dateOrField`
///
/// Examples:
/// - `after:today`
/// - `after:start_date`
class AfterRule extends Rule {
  @override
  String get signature => 'after';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    final data = context.data;
    if (value == null) return false;
    if (value is! String) return false;

    try {
      final valueDate = DateTime.parse(value);
      DateTime compareDate;
      final arg = args.isNotEmpty ? args[0] : null;

      if (arg == 'today') {
        compareDate = DateTime.now();
      } else if (arg == 'tomorrow') {
        compareDate = DateTime.now().add(const Duration(days: 1));
      } else if (arg == 'yesterday') {
        compareDate = DateTime.now().subtract(const Duration(days: 1));
      } else if (arg != null && data.containsKey(arg)) {
        final otherValue = data[arg];
        if (otherValue is String) {
          compareDate = DateTime.parse(otherValue);
        } else {
          return false;
        }
      } else if (arg != null) {
        compareDate = DateTime.parse(arg);
      } else {
        return false;
      }

      return valueDate.isAfter(compareDate);
    } catch (e) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'after_validation';
}
