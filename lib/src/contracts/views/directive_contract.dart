// directives/directive_contract.dart
abstract class ViewDirective {
  Future<String> apply(String content, Map<String, dynamic> context);
}
