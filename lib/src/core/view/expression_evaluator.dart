/// ExpressionEvaluator handles the evaluation of complex template expressions
/// like user.name, items[0], user.profile.email, etc.
class ExpressionEvaluator {
  /// Evaluates a complex expression against a context map
  /// Supports dot notation, array access with brackets and dots, and property access
  dynamic evaluate(String expression, Map<String, dynamic> context) {
    if (expression.isEmpty) return null;

    try {
      final parts = _parseExpression(expression);
      dynamic current = context;

      for (final part in parts) {
        current = _resolvePart(current, part);
        if (current == null) break; // Safe navigation
      }

      return current;
    } catch (e) {
      // Return null for any evaluation errors
      return null;
    }
  }

  /// Parses an expression into parts, handling different access patterns
  List<String> _parseExpression(String expression) {
    // Handle array access with brackets first: items[0].name -> ['items[0]', 'name']
    final bracketRegex = RegExp(r'(\w+\[\d+\]|[^\.\[\]]+)');
    return bracketRegex.allMatches(expression).map((m) => m.group(0)!).toList();
  }

  /// Resolves a single part of an expression
  dynamic _resolvePart(dynamic obj, String part) {
    if (obj == null) return null;

    // Handle array/list access with brackets: items[0]
    final bracketMatch = RegExp(r'^(\w+)\[(\d+)\]$').firstMatch(part);
    if (bracketMatch != null) {
      final propName = bracketMatch.group(1)!;
      final index = int.parse(bracketMatch.group(2)!);
      return _getIndexedProperty(obj, propName, index);
    }

    // Handle array/list access with dot notation: items.0
    final dotIndexMatch = RegExp(r'^(\w+)\.(\d+)$').firstMatch(part);
    if (dotIndexMatch != null) {
      final propName = dotIndexMatch.group(1)!;
      final index = int.parse(dotIndexMatch.group(2)!);
      return _getIndexedProperty(obj, propName, index);
    }

    // Handle regular property access
    return _getProperty(obj, part);
  }

  /// Gets a property from an object with array indexing support
  dynamic _getIndexedProperty(dynamic obj, String property, int index) {
    final target = _getProperty(obj, property);
    if (target is List && index < target.length) {
      return target[index];
    }
    return null;
  }

  /// Gets a property from an object, supporting Maps and Lists
  dynamic _getProperty(dynamic obj, String property) {
    if (obj == null) return null;

    // Handle Map access
    if (obj is Map) {
      return obj[property];
    }

    // Handle List access by index
    if (obj is List && int.tryParse(property) != null) {
      final index = int.parse(property);
      return index < obj.length ? obj[index] : null;
    }

    // Handle common collection properties
    return _getCollectionProperty(obj, property);
  }

  /// Gets common properties from collections and strings
  dynamic _getCollectionProperty(dynamic obj, String property) {
    try {
      switch (property) {
        case 'length':
          if (obj is String || obj is List || obj is Map) {
            return obj.length;
          }
          break;
        case 'isEmpty':
          if (obj is String || obj is List || obj is Map) {
            return obj.isEmpty;
          }
          break;
        case 'isNotEmpty':
          if (obj is String || obj is List || obj is Map) {
            return obj.isNotEmpty;
          }
          break;
        case 'first':
          if (obj is List && obj.isNotEmpty) {
            return obj.first;
          }
          break;
        case 'last':
          if (obj is List && obj.isNotEmpty) {
            return obj.last;
          }
          break;
      }
    } catch (e) {
      // Ignore any reflection or access errors
    }

    return null;
  }
}
