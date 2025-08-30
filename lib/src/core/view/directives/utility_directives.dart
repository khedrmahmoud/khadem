import '../../../contracts/views/directive_contract.dart';
import '../../../application/khadem.dart';

/// Environment and configuration directives
class EnvDirective implements ViewDirective {
  static final _envRegex = RegExp(r'@env\s*\(\s*(.+?)\s*(?:,\s*(.+?)\s*)?\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_envRegex, (match) {
      final key = match.group(1)!.trim();
      final defaultValue = match.group(2)?.trim();

      // Remove quotes if present
      final cleanKey = key.replaceAll('"', '').replaceAll("'", '');

      try {
        // Try to get the environment variable
        final envValue = Khadem.env.get(cleanKey);
        if (envValue != null) {
          return envValue;
        }

        // If not found and default value provided, return it
        if (defaultValue != null) {
          final cleanDefault = defaultValue.replaceAll('"', '').replaceAll("'", '');
          return cleanDefault;
        }
      } catch (_) {
        // If there's an error, return default value
        if (defaultValue != null) {
          final cleanDefault = defaultValue.replaceAll('"', '').replaceAll("'", '');
          return cleanDefault;
        }
      }

      return '';
    });
  }
}

class ConfigDirective implements ViewDirective {
  static final _configRegex = RegExp(r'@config\s*\(\s*(.+?)\s*(?:,\s*(.+?)\s*)?\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_configRegex, (match) {
      final key = match.group(1)!.trim();
      final defaultValue = match.group(2)?.trim();

      // Remove quotes if present
      final cleanKey = key.replaceAll('"', '').replaceAll("'", '');

      try {
        // Try to get the configuration value
        final configValue = Khadem.config.get<String>(cleanKey);
        if (configValue != null) {
          return configValue;
        }

        // If not found and default value provided, return it
        if (defaultValue != null) {
          final cleanDefault = defaultValue.replaceAll('"', '').replaceAll("'", '');
          return cleanDefault;
        }
      } catch (_) {
        // If there's an error, return default value
        if (defaultValue != null) {
          final cleanDefault = defaultValue.replaceAll('"', '').replaceAll("'", '');
          return cleanDefault;
        }
      }

      return '';
    });
  }
}

/// Time and date directives
class NowDirective implements ViewDirective {
  static final _nowRegex = RegExp(r'@now\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_nowRegex, (match) {
      final format = match.group(1)!.trim();

      // Remove quotes if present
      final cleanFormat = format.replaceAll('"', '').replaceAll("'", '');

      try {
        final now = DateTime.now();

        // Simple date formatting - in a real implementation, use intl package
        // For now, provide basic formatting
        switch (cleanFormat) {
          case 'Y-m-d':
            return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          case 'Y-m-d H:i:s':
            return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
                   '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          case 'H:i:s':
            return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          case 'Y':
            return now.year.toString();
          case 'm':
            return now.month.toString().padLeft(2, '0');
          case 'd':
            return now.day.toString().padLeft(2, '0');
          default:
            return now.toIso8601String();
        }
      } catch (_) {
        return DateTime.now().toIso8601String();
      }
    });
  }
}

class FormatDirective implements ViewDirective {
  static final _formatRegex = RegExp(r'@format\s*\(\s*(.+?)\s*,\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_formatRegex, (match) {
      final dateExpr = match.group(1)!.trim();
      final format = match.group(2)!.trim();

      try {
        final date = _evaluate(dateExpr, context);
        if (date is DateTime) {
          // Remove quotes if present from format
          final cleanFormat = format.replaceAll('"', '').replaceAll("'", '');

          // Simple date formatting - in a real implementation, use intl package
          switch (cleanFormat) {
            case 'Y-m-d':
              return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            case 'Y-m-d H:i:s':
              return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                     '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
            case 'H:i:s':
              return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
            case 'Y':
              return date.year.toString();
            case 'm':
              return date.month.toString().padLeft(2, '0');
            case 'd':
              return date.day.toString().padLeft(2, '0');
            default:
              return date.toIso8601String();
          }
        }
      } catch (_) {
        // Ignore errors
      }

      return '';
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    // Handle quoted strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      final unquoted = expr.substring(1, expr.length - 1);
      // Try to parse as DateTime
      try {
        return DateTime.parse(unquoted);
      } catch (_) {
        return unquoted;
      }
    }

    // Handle context variables
    if (context.containsKey(expr)) {
      return context[expr];
    }

    // Try to parse as DateTime
    try {
      return DateTime.parse(expr);
    } catch (_) {
      // Ignore parsing errors
    }

    return expr;
  }
}

/// Math directives
class MathDirective implements ViewDirective {
  static final _mathRegex = RegExp(r'@math\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_mathRegex, (match) {
      final expression = match.group(1)!.trim();

      try {
        final result = _evaluateMath(expression, context);
        return result.toString();
      } catch (_) {
        return '0';
      }
    });
  }

  num _evaluateMath(String expr, Map<String, dynamic> context) {
    // Replace context variables with their values
    var processedExpr = expr;

    // Find all variable references (word characters)
    final varRegex = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b');
    final matches = varRegex.allMatches(expr);

    for (final match in matches) {
      final varName = match.group(0)!;
      if (context.containsKey(varName)) {
        final value = context[varName];
        if (value is num) {
          processedExpr = processedExpr.replaceAll(varName, value.toString());
        }
      }
    }

    // Simple math evaluation for basic operations
    try {
      return _parseExpression(processedExpr);
    } catch (_) {
      return 0;
    }
  }

  num _parseExpression(String expr) {
    // Remove spaces
    var cleanExpr = expr.replaceAll(' ', '');

    // Handle parentheses recursively
    while (cleanExpr.contains('(')) {
      final openParen = cleanExpr.lastIndexOf('(');
      final closeParen = cleanExpr.indexOf(')', openParen);
      if (closeParen == -1) break;

      final subExpr = cleanExpr.substring(openParen + 1, closeParen);
      final subResult = _parseExpression(subExpr);
      cleanExpr = cleanExpr.replaceRange(openParen, closeParen + 1, subResult.toString());
    }

    // Handle multiplication and division first (higher precedence)
    final mulDivRegex = RegExp(r'(\d+(?:\.\d+)?)([*/])(\d+(?:\.\d+)?)');
    var match = mulDivRegex.firstMatch(cleanExpr);
    while (match != null) {
      final left = num.parse(match.group(1)!);
      final op = match.group(2)!;
      final right = num.parse(match.group(3)!);

      num result;
      if (op == '*') {
        result = left * right;
      } else if (right != 0) {
        result = left / right;
      } else {
        return 0; // Division by zero
      }

      cleanExpr = cleanExpr.replaceRange(match.start, match.end, result.toString());
      match = mulDivRegex.firstMatch(cleanExpr);
    }

    // Handle addition and subtraction
    final addSubRegex = RegExp(r'(\d+(?:\.\d+)?)([+-])(\d+(?:\.\d+)?)');
    match = addSubRegex.firstMatch(cleanExpr);
    while (match != null) {
      final left = num.parse(match.group(1)!);
      final op = match.group(2)!;
      final right = num.parse(match.group(3)!);

      num result;
      if (op == '+') {
        result = left + right;
      } else {
        result = left - right;
      }

      cleanExpr = cleanExpr.replaceRange(match.start, match.end, result.toString());
      match = addSubRegex.firstMatch(cleanExpr);
    }

    return num.tryParse(cleanExpr) ?? 0;
  }
}
