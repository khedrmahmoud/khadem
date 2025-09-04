 
import 'package:khadem/src/contracts/views/directive_contract.dart';

/// Error handling directives
class ErrorDirective implements ViewDirective {
  static final _errorRegex = RegExp(r'@error\s*\(\s*(.+?)\s*\)(.*?)@enderror', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_errorRegex, (match) {
      final field = match.group(1)!.trim();
      final body = match.group(2)!.trim();

      // Remove quotes if present
      final cleanField = field.replaceAll('"', '').replaceAll("'", '');

      // Check if there are errors for this field
      final hasError = _hasError(cleanField, context);

      return hasError ? body : '';
    });
  }

  bool _hasError(String field, Map<String, dynamic> context) {
    if (context.containsKey('errors') && context['errors'] is Map) {
      final errors = context['errors'] as Map;
      return errors.containsKey(field) && (errors[field] as List).isNotEmpty;
    }
    return false;
  }
}

class ErrorsDirective implements ViewDirective {
  static final _errorsRegex = RegExp(r'@errors\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_errorsRegex, (match) {
      final field = match.group(1)!.trim();

      // Remove quotes if present
      final cleanField = field.replaceAll('"', '').replaceAll("'", '');

      // Get errors for this field
      final fieldErrors = _getFieldErrors(cleanField, context);

      if (fieldErrors.isNotEmpty) {
        return '<ul class="errors">${fieldErrors.map((error) => '<li>$error</li>').join()}</ul>';
      }

      return '';
    });
  }

  List<String> _getFieldErrors(String field, Map<String, dynamic> context) {
    if (context.containsKey('errors') && context['errors'] is Map) {
      final errors = context['errors'] as Map;
      if (errors.containsKey(field) && errors[field] is List) {
        return (errors[field] as List).cast<String>();
      }
    }
    return [];
  }
}

/// Component directives
class ComponentDirective implements ViewDirective {
  static final _componentRegex = RegExp(r'@component\s*\(\s*(.+?)\s*\)(.*?)@endComponent', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_componentRegex, (match) {
      final componentName = match.group(1)!.trim();
      final componentContent = match.group(2)!;

      // Remove quotes if present
      final cleanComponentName = componentName.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would render a component
      // For now, wrap the content in a div with component class
      return '<div class="component-$cleanComponentName">$componentContent</div>';
    });
  }
}

class SlotDirective implements ViewDirective {
  static final _slotRegex = RegExp(r'@slot\s*\(\s*(.+?)\s*\)(.*?)@endSlot', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_slotRegex, (match) {
      final slotName = match.group(1)!.trim();
      final slotContent = match.group(2)!;

      // Remove quotes if present
      final cleanSlotName = slotName.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would define a slot
      // For now, just return the content with slot name
      return '<!-- slot: $cleanSlotName -->$slotContent';
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
            final className = parts[0].trim().replaceAll('"', '').replaceAll("'", '');
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
