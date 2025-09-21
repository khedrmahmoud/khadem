import '../../contracts/validation/rule.dart';

class IntRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value is int) return null;
    if (value is String && int.tryParse(value) != null) return null;
    return 'int_validation';
  }
}
