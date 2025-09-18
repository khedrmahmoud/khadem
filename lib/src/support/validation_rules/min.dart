import '../../contracts/validation/rule.dart';

class MinRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    final min = int.tryParse(arg ?? '') ?? 0;

    if (value == null) return null;

    if (value is num) {
      if (value < min) {
        return 'min_value_validation';
      }
    } else if (value is String) {
      // Try to parse as number first
      final numValue = num.tryParse(value);
      if (numValue != null) {
        if (numValue < min) {
          return 'min_value_validation';
        }
      } else {
        // If not a number, check string length
        if (value.length < min) {
          return 'min_validation';
        }
      }
    } else if (value is List || value is Map) {
      if (value.length < min) {
        return 'min_validation';
      }
    } else {
      final str = value.toString();
      if (str.length < min) {
        return 'min_validation';
      }
    }

    return null;
  }
}
