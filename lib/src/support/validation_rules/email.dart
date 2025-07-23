import '../../contracts/validation/rule.dart';

class EmailRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (value is String && !emailRegex.hasMatch(value)) {
      return 'email_validation';
    }
    return null;
  }
}
