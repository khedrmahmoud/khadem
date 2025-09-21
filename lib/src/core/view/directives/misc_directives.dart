import 'package:khadem/src/contracts/views/directive_contract.dart';

/// Component directives
class ComponentDirective implements ViewDirective {
  static final _componentRegex =
      RegExp(r'@component\s*\(\s*(.+?)\s*\)(.*?)@endComponent', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_componentRegex, (match) {
      final componentName = match.group(1)!.trim();
      final componentContent = match.group(2)!;

      // Remove quotes if present
      final cleanComponentName =
          componentName.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would render a component
      // For now, wrap the content in a div with component class
      return '<div class="component-$cleanComponentName">$componentContent</div>';
    });
  }
}

/// Conditional class directives
class ClassDirective implements ViewDirective {
  static final _classRegex = RegExp(r'@class\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_classRegex, (match) {
      final condition = match.group(1)!.trim();

      try {
        final result = _evaluate(condition, context);
        return result;
      } catch (_) {
        return '';
      }
    });
  }

  String _evaluate(String expr, Map<String, dynamic> context) {
    // Handle map syntax like ["active": isActive, "disabled": isDisabled]
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final mapContent = expr.substring(1, expr.length - 1).trim();
      final classes = <String>[];

      // Simple parsing of key-value pairs
      final pairs = mapContent.split(',');
      for (final pair in pairs) {
        final trimmedPair = pair.trim();
        if (trimmedPair.contains(':')) {
          final parts = trimmedPair.split(':');
          if (parts.length == 2) {
            final className =
                parts[0].trim().replaceAll('"', '').replaceAll("'", '');
            final condition = parts[1].trim();

            // Evaluate the condition
            final conditionValue = _evaluateCondition(condition, context);
            if (conditionValue) {
              classes.add(className);
            }
          }
        }
      }

      return classes.join(' ');
    }

    // Handle simple condition
    final value = context[expr];
    if (value is bool) return value ? 'class' : '';
    return value != null ? 'class' : '';
  }

  bool _evaluateCondition(String condition, Map<String, dynamic> context) {
    final value = context[condition];
    if (value is bool) return value;
    return value != null;
  }
}

class SelectedDirective implements ViewDirective {
  static final _selectedRegex = RegExp(r'@selected\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_selectedRegex, (match) {
      final condition = match.group(1)!.trim();

      try {
        final result = _evaluate(condition, context);
        return result ? 'selected' : '';
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

class CheckedDirective implements ViewDirective {
  static final _checkedRegex = RegExp(r'@checked\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_checkedRegex, (match) {
      final condition = match.group(1)!.trim();

      try {
        final result = _evaluate(condition, context);
        return result ? 'checked' : '';
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
