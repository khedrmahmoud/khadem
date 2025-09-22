import 'package:khadem/src/contracts/views/directive_contract.dart';

/// Data manipulation directives
class SetDirective implements ViewDirective {
  static final _setRegex = RegExp(r'@set\s*\(\s*(\w+)\s*,\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_setRegex, (match) {
      final variable = match.group(1)!;
      final valueExpr = match.group(2)!.trim();

      try {
        final value = _evaluate(valueExpr, context);
        context[variable] = value;
      } catch (_) {
        // Ignore evaluation errors
      }

      return '';
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    final trimmed = expr.trim();

    // Handle quoted strings
    if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
        (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
      return trimmed.substring(1, trimmed.length - 1);
    }

    // Handle numbers
    final numValue = num.tryParse(trimmed);
    if (numValue != null) return numValue;

    // Handle boolean values
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;

    // Handle null
    if (trimmed == 'null') return null;

    // Handle context variables
    if (context.containsKey(trimmed)) {
      return context[trimmed];
    }

    return trimmed;
  }
}

class UnsetDirective implements ViewDirective {
  static final _unsetRegex = RegExp(r'@unset\s*\(\s*(\w+)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_unsetRegex, (match) {
      final variable = match.group(1)!;
      context.remove(variable);
      return '';
    });
  }
}

class PushDirective implements ViewDirective {
  static final _pushRegex =
      RegExp(r'@push\s*\(\s*(\w+)\s*\)(.*?)@endPush', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_pushRegex, (match) {
      final stackName = match.group(1)!;
      final content = match.group(2)!;

      if (!context.containsKey(stackName)) {
        context[stackName] = <String>[];
      }

      if (context[stackName] is List) {
        (context[stackName] as List).add(content);
      }

      return '';
    });
  }
}

class StackDirective implements ViewDirective {
  static final _stackRegex = RegExp(r'@stack\s*\(\s*(\w+)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_stackRegex, (match) {
      final stackName = match.group(1)!;

      if (context.containsKey(stackName) && context[stackName] is List) {
        final stack = context[stackName] as List;
        return stack.join('\n');
      }

      return '';
    });
  }
}
