import '../../contracts/validation/rule.dart';

class BoolRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value is bool) return null;
    if (value is String && (value == 'true' || value == 'false')) return null;
    return 'bool_validation';
  }
}
