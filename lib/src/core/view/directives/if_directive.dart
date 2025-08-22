import '../../../../khadem_dart.dart';

class IfDirective implements ViewDirective {
  static final _regex = RegExp(r'@if\s*\((.*?)\)(.*?)@endIf', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_regex, (match) {
      final condition = match.group(1)?.trim();
      final body = match.group(2);

      try {
        final value = _evaluate(condition!, context);
        return value ? body! : '';
      } catch (_) {
        return '';
      }
    });
  }

  bool _evaluate(String expr, Map<String, dynamic> context) {
    final value = context[expr];
    if (value is bool) return value;
    return value != null;
  }
}
