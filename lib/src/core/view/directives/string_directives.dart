import 'package:khadem/src/contracts/views/directive_contract.dart';

/// String manipulation directives
class StrtoupperDirective implements ViewDirective {
  static final _strtoupperRegex = RegExp(r'@strtoupper\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_strtoupperRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        return value.toString().toUpperCase();
      } catch (_) {
        return '';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      return expr.substring(1, expr.length - 1);
    }

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    return expr;
  }
}

class StrtolowerDirective implements ViewDirective {
  static final _strtolowerRegex = RegExp(r'@strtolower\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_strtolowerRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        return value.toString().toLowerCase();
      } catch (_) {
        return '';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      return expr.substring(1, expr.length - 1);
    }

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    return expr;
  }
}

class StrlenDirective implements ViewDirective {
  static final _strlenRegex = RegExp(r'@strlen\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_strlenRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        return value.toString().length.toString();
      } catch (_) {
        return '0';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      return expr.substring(1, expr.length - 1);
    }

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    return expr;
  }
}

class SubstrDirective implements ViewDirective {
  static final _substrRegex =
      RegExp(r'@substr\s*\(\s*(.+?)\s*,\s*(.+?)\s*(?:,\s*(.+?)\s*)?\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_substrRegex, (match) {
      final strExpr = match.group(1)!.trim();
      final startExpr = match.group(2)!.trim();
      final lengthExpr = match.group(3)?.trim();

      try {
        final str = _evaluate(strExpr, context).toString();
        final start = int.parse(_evaluate(startExpr, context).toString());

        if (lengthExpr != null) {
          final length = int.parse(_evaluate(lengthExpr, context).toString());
          return str.substring(start, start + length);
        } else {
          return str.substring(start);
        }
      } catch (_) {
        return '';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      return expr.substring(1, expr.length - 1);
    }

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    return expr;
  }
}

class ReplaceDirective implements ViewDirective {
  static final _replaceRegex =
      RegExp(r'@replace\s*\(\s*(.+?)\s*,\s*(.+?)\s*,\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_replaceRegex, (match) {
      final strExpr = match.group(1)!.trim();
      final searchExpr = match.group(2)!.trim();
      final replaceExpr = match.group(3)!.trim();

      try {
        final str = _evaluate(strExpr, context).toString();
        final search = _evaluate(searchExpr, context).toString();
        final replace = _evaluate(replaceExpr, context).toString();

        return str.replaceAll(search, replace);
      } catch (_) {
        return '';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      return expr.substring(1, expr.length - 1);
    }

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    return expr;
  }
}
