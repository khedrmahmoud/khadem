import '../../../contracts/views/directive_contract.dart';

/// Enhanced loop directives
class ForeachDirective implements ViewDirective {
  static final _foreachRegex = RegExp(
    r'@foreach\s*\(\s*(\w+)\s+as\s+(\w+)(?:\s*=>\s*(\w+))?\s*\)(.*?)@endforeach',
    dotAll: true,
  );

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_foreachRegex, (match) {
      final arrayName = match.group(1)!;
      final valueVar = match.group(2)!;
      final keyVar = match.group(3);
      final loopBody = match.group(4)!;

      final array = context[arrayName];
      if (array is! List && array is! Map) {
        return '';
      }

      final buffer = StringBuffer();

      if (array is List) {
        for (var i = 0; i < array.length; i++) {
          var rendered = loopBody;
          final item = array[i];

          // Replace value variable
          rendered = _replaceVariable(rendered, valueVar, item.toString());

          // Replace key variable (index)
          if (keyVar != null) {
            rendered = _replaceVariable(rendered, keyVar, i.toString());
          }

          buffer.write(rendered);
        }
      } else if (array is Map) {
        array.forEach((key, value) {
          var rendered = loopBody;

          // Replace value variable
          rendered = _replaceVariable(rendered, valueVar, value.toString());

          // Replace key variable
          if (keyVar != null) {
            rendered = _replaceVariable(rendered, keyVar, key.toString());
          }

          buffer.write(rendered);
        });
      }

      return buffer.toString();
    });
  }

  String _replaceVariable(String content, String variable, String value) {
    final patterns = [
      RegExp(r'{{\s*' + variable + r'\s*}}'),
      RegExp(r'{{\s*\$' + variable + r'\s*}}'),
    ];

    for (var pattern in patterns) {
      content = content.replaceAll(pattern, value);
    }

    return content;
  }
}

class WhileDirective implements ViewDirective {
  static final _whileRegex = RegExp(
    r'@while\s*\((.*?)\)(.*?)@endWhile',
    dotAll: true,
  );

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_whileRegex, (match) {
      final condition = match.group(1)?.trim();
      final body = match.group(2);

      if (condition == null || body == null) return '';

      final buffer = StringBuffer();
      var iterations = 0;
      const maxIterations = 1000; // Prevent infinite loops

      while (iterations < maxIterations) {
        try {
          final shouldContinue = _evaluate(condition, context);
          if (!shouldContinue) break;

          buffer.write(body);
          iterations++;
        } catch (_) {
          break;
        }
      }

      return buffer.toString();
    });
  }

  bool _evaluate(String expr, Map<String, dynamic> context) {
    final value = context[expr];
    if (value is bool) return value;
    return value != null;
  }
}

class BreakDirective implements ViewDirective {
  static final _breakRegex = RegExp(r'@break');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    // This directive is handled by the loop directives
    // For now, just remove the directive
    return content.replaceAll(_breakRegex, '');
  }
}

class ContinueDirective implements ViewDirective {
  static final _continueRegex = RegExp(r'@continue');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    // This directive is handled by the loop directives
    // For now, just remove the directive
    return content.replaceAll(_continueRegex, '');
  }
}
