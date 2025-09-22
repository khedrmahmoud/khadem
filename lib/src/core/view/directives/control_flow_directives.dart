import 'package:khadem/src/contracts/views/directive_contract.dart';

/// Control flow directives
class UnlessDirective implements ViewDirective {
  static final _regex =
      RegExp(r'@unless\s*\((.*?)\)(.*?)@endunless', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_regex, (match) {
      final condition = match.group(1)?.trim();
      final body = match.group(2)?.trim();

      try {
        final value = _evaluate(condition!, context);
        return !value ? body! : '';
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

class ElseIfDirective implements ViewDirective {
  static final _regex = RegExp(r'@elseif\s*\((.*?)\)(.*?)@endif', dotAll: true);

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

class ElseDirective implements ViewDirective {
  static final _regex = RegExp(r'@else(.*?)@endif', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_regex, (match) {
      return match.group(1)!;
    });
  }
}

class SwitchDirective implements ViewDirective {
  static final _switchRegex =
      RegExp(r'@switch\s*\((.*?)\)(.*?)@endswitch', dotAll: true);
  static final _caseRegex =
      RegExp(r'@case\s*\((.*?)\)(.*?)@endcase', dotAll: true);
  static final _defaultRegex =
      RegExp(r'@default(.*?)@enddefault', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_switchRegex, (match) {
      final switchValue = _evaluate(match.group(1)!.trim(), context);
      final switchBody = match.group(2)!;

      // Process cases
      var processedBody = switchBody;
      var defaultContent = '';

      // Extract default first
      final defaultMatch = _defaultRegex.firstMatch(processedBody);
      if (defaultMatch != null) {
        defaultContent = defaultMatch.group(1)!;
        processedBody = processedBody.replaceFirst(_defaultRegex, '');
      }

      // Process cases
      processedBody = processedBody.replaceAllMapped(_caseRegex, (caseMatch) {
        final caseValue = _evaluate(caseMatch.group(1)!.trim(), context);
        final caseBody = caseMatch.group(2)!;

        if (caseValue == switchValue) {
          return caseBody;
        }
        return '';
      });

      // If no case matched, return default
      if (processedBody.trim().isEmpty && defaultContent.isNotEmpty) {
        return defaultContent;
      }

      return processedBody;
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      return expr.substring(1, expr.length - 1);
    }

    // Handle numbers
    final numValue = num.tryParse(expr);
    if (numValue != null) return numValue;

    // Handle boolean values
    if (expr == 'true') return true;
    if (expr == 'false') return false;

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    return expr;
  }
}
