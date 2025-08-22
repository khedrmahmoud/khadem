import 'package:khadem/khadem_dart.dart';

class LangDirective implements ViewDirective {
  static final _langRegex = RegExp(
      r"""@lang\s*\(\s*['"](.+?)['"]\s*(?:,\s*field\s*:\s*(.+?))?\s*(?:,\s*arg\s*:\s*(.+?))?\s*\)""");

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_langRegex, (match) {
      final key = match.group(1)!;
      final fieldRaw = match.group(2)?.trim();
      final argRaw = match.group(3)?.trim();

      String? resolve(String? raw) {
        if (raw == null) return null;
        // If quoted, treat as constant
        if ((raw.startsWith("'") && raw.endsWith("'")) ||
            (raw.startsWith('"') && raw.endsWith('"'))) {
          return raw.substring(1, raw.length - 1);
        }
        // Otherwise treat as variable
        return context[raw]?.toString();
      }

      final field = resolve(fieldRaw);
      final arg = resolve(argRaw);

      return Lang.t(
        key,
        field: field ?? '',
        arg: arg,
      );
    });
  }
}
