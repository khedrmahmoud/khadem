import '../../contracts/validation/rule.dart';

class ConfirmedRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    final confirmation = data['${field}_confirmation'];
    if (value != confirmation) {
      return 'confirmed_validation';
    }
    return null;
  }
}
