import '../../contracts/validation/rule.dart';

class RequiredRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'required_validation';
    }
    return null;
  }
}
