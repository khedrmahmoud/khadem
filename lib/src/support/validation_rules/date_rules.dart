import '../../contracts/validation/rule.dart';

class DateRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'date_validation';
    }

    if (value is! String) {
      return 'date_validation';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'date_validation';
    }
  }
}

class DateFormatRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'date_format_validation';
    }

    if (value is! String) {
      return 'date_format_validation';
    }

    try {
      // For now, we'll only support ISO 8601 format
      // In a real implementation, this would support various date formats
      if (arg == 'Y-m-d' || arg == 'Y/m/d') {
        final dateRegex = RegExp(r'^\d{4}[-/]\d{2}[-/]\d{2}$');
        if (!dateRegex.hasMatch(value)) {
          return 'date_format_validation';
        }
        // Validate the date is actually valid
        final parts = value.split(RegExp(r'[-/]'));
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        final date = DateTime(year, month, day);
        if (date.year != year || date.month != month || date.day != day) {
          return 'date_format_validation';
        }
      } else {
        // For other formats, try parsing as DateTime
        DateTime.parse(value);
      }
      return null;
    } catch (e) {
      return 'date_format_validation';
    }
  }
}

class BeforeRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'before_validation';
    }

    if (value is! String) {
      return 'before_validation';
    }

    try {
      final valueDate = DateTime.parse(value);
      DateTime compareDate;

      if (arg == 'today') {
        compareDate = DateTime.now();
      } else if (arg == 'tomorrow') {
        compareDate = DateTime.now().add(const Duration(days: 1));
      } else if (arg == 'yesterday') {
        compareDate = DateTime.now().subtract(const Duration(days: 1));
      } else if (data.containsKey(arg!)) {
        final otherValue = data[arg];
        if (otherValue is String) {
          compareDate = DateTime.parse(otherValue);
        } else {
          return 'before_validation';
        }
      } else {
        // Try parsing arg as a date
        compareDate = DateTime.parse(arg);
      }

      if (!valueDate.isBefore(compareDate)) {
        return 'before_validation';
      }

      return null;
    } catch (e) {
      return 'before_validation';
    }
  }
}

class AfterRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'after_validation';
    }

    if (value is! String) {
      return 'after_validation';
    }

    try {
      final valueDate = DateTime.parse(value);
      DateTime compareDate;

      if (arg == 'today') {
        compareDate = DateTime.now();
      } else if (arg == 'tomorrow') {
        compareDate = DateTime.now().add(const Duration(days: 1));
      } else if (arg == 'yesterday') {
        compareDate = DateTime.now().subtract(const Duration(days: 1));
      } else if (data.containsKey(arg!)) {
        final otherValue = data[arg];
        if (otherValue is String) {
          compareDate = DateTime.parse(otherValue);
        } else {
          return 'after_validation';
        }
      } else {
        // Try parsing arg as a date
        compareDate = DateTime.parse(arg);
      }

      if (!valueDate.isAfter(compareDate)) {
        return 'after_validation';
      }

      return null;
    } catch (e) {
      return 'after_validation';
    }
  }
}
