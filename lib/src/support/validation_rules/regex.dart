import '../../contracts/validation/rule.dart';

class RegexRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (arg == null) return null;
    final regex = RegExp(arg);
    if (value is String && regex.hasMatch(value)) return null;
    return 'regex_validation';
  }
}
