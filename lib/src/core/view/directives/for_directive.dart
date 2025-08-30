import '../../../contracts/views/directive_contract.dart';

class ForDirective implements ViewDirective {
  static final _forRegex = RegExp(
    r'@for\s*\(\s*(\w+)\s+in\s+(\w+)\s*\)(.*?)@endFor',
    dotAll: true,
  );

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_forRegex, (match) {
      final itemVar = match.group(1)!;
      final listName = match.group(2)!;
      final loopBody = match.group(3)!;

      final list = context[listName];
      if (list is List) {
        final buffer = StringBuffer();

        for (var item in list) {
          var rendered = loopBody;

          // Support for {{item}} or {{$item}} or {{ $item }} inside the loop
          final variablePatterns = [
            RegExp(r'{{\s*' + itemVar + r'\s*}}'),
            RegExp(r'\{\{\s*\$' + itemVar + r'\s*\}\}'),
          ];

          for (var pattern in variablePatterns) {
            rendered =
                rendered.replaceAllMapped(pattern, (_) => item.toString());
          }

          buffer.write(rendered);
        }
        return buffer.toString();
      }

      return '';
    });
  }
}
