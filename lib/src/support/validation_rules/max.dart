import '../../contracts/validation/rule.dart';

class MaxRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    final max = int.tryParse(arg ?? '') ?? 9999;
    if (value is String || value is List || value is Map) {
      if (value.length > max) {
        return 'max _validation';
      }
    } else if (value is num) {
      if (value > max) {
        return 'max_value_validation';
      }
    } else {
      final str = value.toString();
      if (str.length > max) {
        return 'max_validation';
      }
    }

    return null;
  }
}
