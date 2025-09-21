import '../../contracts/validation/rule.dart';

class NumericRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value is num) return null;
    if (value is String && num.tryParse(value) != null) return null;
    return 'numeric_validation';
  }
}
