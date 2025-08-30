import 'package:khadem/khadem_dart.dart';

class LangDirective implements ViewDirective {
  // Regex patterns for different directive types
  static final _langRegex = RegExp(
    '@lang\\s*\\(\\s*(["\'](.+?)["\'])\\s*(?:,\\s*(.+?))?\\s*\\)',
  );

  static final _choiceRegex = RegExp(
    '@choice\\s*\\(\\s*(["\'](.+?)["\'])\\s*,\\s*(.+?)\\s*(?:,\\s*(.+?))?\\s*\\)',
  );

  static final _fieldRegex = RegExp(
    '@field\\s*\\(\\s*(["\'](.+?)["\'])\\s*(?:,\\s*(.+?))?\\s*\\)',
  );

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    String result = content;

    // Process @lang directives
    result = result.replaceAllMapped(_langRegex, (match) {
      final key = match.group(2)!;
      final options = match.group(3);

      return _processLangDirective(key, options, context);
    });

    // Process @choice directives
    result = result.replaceAllMapped(_choiceRegex, (match) {
      final key = match.group(2)!;
      final countExpr = match.group(3)!;
      final options = match.group(4);

      return _processChoiceDirective(key, countExpr, options, context);
    });

    // Process @field directives
    result = result.replaceAllMapped(_fieldRegex, (match) {
      final key = match.group(2)!;
      final options = match.group(3);

      return _processFieldDirective(key, options, context);
    });

    return result;
  }

  String _processLangDirective(String key, String? options, Map<String, dynamic> context) {
    final params = _parseOptions(options, context);

    return Lang.t(
      key,
      parameters: params['parameters'],
      locale: params['locale'],
      namespace: params['namespace'],
    );
  }

  String _processChoiceDirective(String key, String countExpr, String? options, Map<String, dynamic> context) {
    final count = _resolveValue(countExpr, context);
    final params = _parseOptions(options, context);

    if (count is int) {
      return Lang.choice(
        key,
        count,
        parameters: params['parameters'],
        locale: params['locale'],
        namespace: params['namespace'],
      );
    }

    // If count is not an integer, fall back to regular translation
    return Lang.t(
      key,
      parameters: {...?params['parameters'], 'count': count},
      locale: params['locale'],
      namespace: params['namespace'],
    );
  }

  String _processFieldDirective(String key, String? options, Map<String, dynamic> context) {
    final params = _parseOptions(options, context);

    return Lang.getField(
      key,
      locale: params['locale'],
      namespace: params['namespace'],
    );
  }

  Map<String, dynamic> _parseOptions(String? options, Map<String, dynamic> context) {
    if (options == null || options.trim().isEmpty) {
      return {};
    }

    final result = <String, dynamic>{};
    final trimmed = options.trim();

    // Handle parameters: {name: "John", age: 25}
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      result['parameters'] = _parseParameterMap(trimmed, context);
    }
    // Handle parameters: parameters: {name: "John"}
    else if (trimmed.startsWith('parameters:')) {
      final paramStr = trimmed.substring(11).trim(); // Remove 'parameters:'
      result['parameters'] = _parseParameterMap(paramStr, context);
    }
    // Handle locale: "en"
    else if (trimmed.startsWith('locale:')) {
      final localeStr = trimmed.substring(7).trim(); // Remove 'locale:'
      result['locale'] = _resolveValue(localeStr, context);
    }
    // Handle namespace: "auth"
    else if (trimmed.startsWith('namespace:')) {
      final nsStr = trimmed.substring(10).trim(); // Remove 'namespace:'
      result['namespace'] = _resolveValue(nsStr, context);
    }
    // Handle multiple options separated by comma
    else {
      final parts = trimmed.split(',').map((s) => s.trim());
      for (final part in parts) {
        if (part.startsWith('locale:')) {
          result['locale'] = _resolveValue(part.substring(7).trim(), context);
        } else if (part.startsWith('namespace:')) {
          result['namespace'] = _resolveValue(part.substring(10).trim(), context);
        } else if (part.startsWith('parameters:')) {
          final paramStr = part.substring(11).trim();
          result['parameters'] = _parseParameterMap(paramStr, context);
        }
      }
    }

    return result;
  }

  Map<String, dynamic> _parseParameterMap(String paramStr, Map<String, dynamic> context) {
    final map = <String, dynamic>{};
    final trimmed = paramStr.trim();

    // Remove braces if present
    final content = trimmed.startsWith('{') && trimmed.endsWith('}')
        ? trimmed.substring(1, trimmed.length - 1)
        : trimmed;

    if (content.trim().isEmpty) return map;

    // Simple parsing for key-value pairs
    final pairs = content.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);

    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex != -1) {
        final key = pair.substring(0, colonIndex).trim();
        final value = pair.substring(colonIndex + 1).trim();

        // Remove quotes from key if present
        final cleanKey = key.replaceAll('"', '').replaceAll("'", '');
        final resolvedValue = _resolveValue(value, context);

        map[cleanKey] = resolvedValue;
      }
    }

    return map;
  }

  dynamic _resolveContextVariable(String variable, Map<String, dynamic> context) {
    final path = variable.substring(1); // Remove $
    final parts = path.split('.');

    dynamic current = context;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return variable; // Return original if not found
      }
    }

    return current;
  }

  dynamic _resolveValue(String expr, Map<String, dynamic> context) {
    final trimmed = expr.trim();

    // Handle quoted strings
    if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
        (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
      return trimmed.substring(1, trimmed.length - 1);
    }

    // Handle context variables like $user.name
    if (trimmed.startsWith('\$')) {
      return _resolveContextVariable(trimmed, context);
    }

    // Handle numbers
    final numValue = num.tryParse(trimmed);
    if (numValue != null) {
      return numValue;
    }

    // Handle boolean values
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;

    // Handle null
    if (trimmed == 'null') return null;

    // Handle context variables
    if (context.containsKey(trimmed)) {
      return context[trimmed];
    }

    // Handle map/object literals (simple case)
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        // Simple parsing for key-value pairs
        final mapContent = trimmed.substring(1, trimmed.length - 1);
        final pairs = mapContent.split(',').map((s) => s.trim());
        final map = <String, dynamic>{};

        for (final pair in pairs) {
          if (pair.contains(':')) {
            final parts = pair.split(':').map((s) => s.trim()).toList();
            if (parts.length == 2) {
              final key = _resolveValue(parts[0], context);
              final value = _resolveValue(parts[1], context);
              if (key is String) {
                map[key] = value;
              }
            }
          }
        }
        return map;
      } catch (_) {
        // Fall back to treating as string
      }
    }

    // Default to string
    return trimmed;
  }
}
