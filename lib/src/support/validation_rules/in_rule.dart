import '../../contracts/validation/rule.dart';

class InRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    final options = arg?.split(',') ?? [];
    if (options.contains(value?.toString())) return null;
    return 'in_validation';
  }
}
