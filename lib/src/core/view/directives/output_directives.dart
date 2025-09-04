import 'dart:convert';
import 'package:khadem/src/contracts/views/directive_contract.dart';


/// Output and debugging directives
class JsonDirective implements ViewDirective {
  static final _jsonRegex = RegExp(r'@json\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_jsonRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        return jsonEncode(value);
      } catch (_) {
        return '{}';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    if (context.containsKey(expr)) {
      return context[expr];
    }
    return expr;
  }
}

class DumpDirective implements ViewDirective {
  static final _dumpRegex = RegExp(r'@dump\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_dumpRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        return '<pre>${value.toString()}</pre>';
      } catch (_) {
        return '<pre>null</pre>';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    if (context.containsKey(expr)) {
      return context[expr];
    }
    return expr;
  }
}

class DdDirective implements ViewDirective {
  static final _ddRegex = RegExp(r'@dd\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_ddRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        final output = '<pre>Debug: ${value.toString()}</pre>';
        // In a real implementation, this would stop execution
        // For now, just return the debug output
        return output;
      } catch (_) {
        return '<pre>Debug: null</pre>';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    if (context.containsKey(expr)) {
      return context[expr];
    }
    return expr;
  }
}

class CommentDirective implements ViewDirective {
  static final _commentRegex = RegExp(r'@comment(.*?)@endComment', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAll(_commentRegex, '');
  }
}
