import 'package:khadem/src/contracts/views/directive_contract.dart';

/// Array and data checking directives
class CountDirective implements ViewDirective {
  static final _countRegex = RegExp(r'@count\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_countRegex, (match) {
      final expr = match.group(1)!.trim();

      try {
        final value = _evaluate(expr, context);
        if (value is List || value is Map || value is String) {
          return value.length.toString();
        }
        return '0';
      } catch (_) {
        return '0';
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

class EmptyDirective implements ViewDirective {
  static final _emptyRegex =
      RegExp(r'@empty\s*\(\s*(.+?)\s*\)(.*?)@endempty', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_emptyRegex, (match) {
      final expr = match.group(1)!.trim();
      final body = match.group(2)!.trim();

      try {
        final value = _evaluate(expr, context);
        final isEmpty = _isEmpty(value);

        return isEmpty ? body : '';
      } catch (_) {
        return '';
      }
    });
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    if (context.containsKey(expr)) {
      return context[expr];
    }
    return expr;
  }
}

class IssetDirective implements ViewDirective {
  static final _issetRegex =
      RegExp(r'@isset\s*\(\s*(.+?)\s*\)(.*?)@endisset', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_issetRegex, (match) {
      final expr = match.group(1)!.trim();
      final body = match.group(2)!.trim();

      try {
        final value = _evaluate(expr, context);
        final isSet = value != null;

        return isSet ? body : '';
      } catch (_) {
        return '';
      }
    });
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    if (context.containsKey(expr)) {
      return context[expr];
    }
    return null;
  }
}

class HasDirective implements ViewDirective {
  static final _hasRegex =
      RegExp(r'@has\s*\(\s*(.+?)\s*,\s*(.+?)\s*\)(.*?)@endhas', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_hasRegex, (match) {
      final arrayExpr = match.group(1)!.trim();
      final keyExpr = match.group(2)!.trim();
      final body = match.group(3)!;

      try {
        final array = _evaluate(arrayExpr, context);
        final key = _evaluate(keyExpr, context);

        final hasKey = _hasKey(array, key);

        return hasKey ? body : '';
      } catch (_) {
        return '';
      }
    });
  }

  bool _hasKey(dynamic array, dynamic key) {
    if (array is Map) {
      return array.containsKey(key);
    }
    if (array is List && key is int) {
      return key >= 0 && key < array.length;
    }
    return false;
  }

  dynamic _evaluate(String expr, Map<String, dynamic> context) {
    if (context.containsKey(expr)) {
      return context[expr];
    }
    return expr;
  }
}
