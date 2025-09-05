import '../../support/exceptions/validation_exception.dart';
import '../http/request/request_body_parser.dart';
import '../lang/lang.dart';
import 'rule_registry.dart';

/// Enhanced validator that supports Laravel-style nested validation rules
/// Example: 'attachments': 'nullable|array', 'attachments.*': 'file|max:5120'
class AdvancedInputValidator {
  final Map<String, dynamic> data;
  final Map<String, String> rules;
  final Map<String, String> errors = {};

  AdvancedInputValidator(this.data, this.rules);

  bool passes() {
    errors.clear();
    
    // Process all rules, including nested ones
    for (final entry in rules.entries) {
      final fieldPattern = entry.key;
      final ruleString = entry.value;
      
      if (fieldPattern.contains('*')) {
        // Handle nested/wildcard validation (e.g., attachments.*)
        _validateNestedField(fieldPattern, ruleString);
      } else {
        // Handle regular field validation
        _validateField(fieldPattern, ruleString);
      }
    }

    return errors.isEmpty;
  }

  void validate() {
    if (!passes()) {
      throw ValidationException(errors);
    }
  }

  void _validateField(String field, String ruleString) {
    final value = _getFieldValue(field);
    final ruleParts = ruleString.split('|');

    // Check if field is nullable and null - if so, skip validation
    if (_isNullableAndNull(ruleParts, value)) {
      return;
    }

    for (final part in ruleParts) {
      final segments = part.split(':');
      final ruleName = segments[0];
      final ruleArg = segments.length > 1 ? segments[1] : null;

      final rule = ValidationRuleRepository.resolve(ruleName);
      if (rule != null) {
        final messageKey = rule.validate(field, value, ruleArg, data: data);
        if (messageKey != null) {
          errors[field] = _formatErrorMessage(messageKey, field, ruleArg, value);
          break; // Stop at first error for this field
        }
      }
    }
  }

  void _validateNestedField(String fieldPattern, String ruleString) {
    // Convert pattern like "attachments.*" to actual field paths
    final fieldPaths = _expandFieldPattern(fieldPattern);
    
    for (final fieldPath in fieldPaths) {
      _validateField(fieldPath, ruleString);
    }
  }

  List<String> _expandFieldPattern(String pattern) {
    final paths = <String>[];
    
    if (pattern.endsWith('.*')) {
      // Handle array validation like "attachments.*"
      final baseField = pattern.substring(0, pattern.length - 2);
      final baseValue = _getFieldValue(baseField);
      
      if (baseValue is List) {
        for (int i = 0; i < baseValue.length; i++) {
          paths.add('$baseField.$i');
        }
      } else if (baseValue is Map) {
        for (final key in baseValue.keys) {
          paths.add('$baseField.$key');
        }
      }
    } else if (pattern.contains('*')) {
      // Handle more complex patterns (can be extended)
      paths.addAll(_expandComplexPattern(pattern));
    }
    
    return paths;
  }

  List<String> _expandComplexPattern(String pattern) {
    // This can be extended to handle more complex patterns like:
    // "users.*.profile.email", "data.*.files.*", etc.
    final paths = <String>[];
    
    // For now, just return the pattern as is
    // This can be enhanced based on specific requirements
    paths.add(pattern);
    
    return paths;
  }

  dynamic _getFieldValue(String fieldPath) {
    final parts = fieldPath.split('.');
    dynamic current = data;
    
    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    
    return current;
  }

  bool _isNullableAndNull(List<String> ruleParts, dynamic value) {
    final hasNullable = ruleParts.any((part) => part.split(':')[0] == 'nullable');
    return hasNullable && value == null;
  }

  String _formatErrorMessage(String messageKey, String field, String? arg, dynamic value) {
    final parameters = <String, dynamic>{'field': field, 'arg': arg};
    
    // Add file-specific parameters for better error messages
    if (_isFileValidationContext(messageKey, value)) {
      _addFileValidationParameters(parameters, messageKey, value, arg);
    }
    
    return Lang.t(messageKey, parameters: parameters);
  }

  bool _isFileValidationContext(String messageKey, dynamic value) {
    return messageKey.contains('file') || 
           messageKey.contains('image') || 
           messageKey.contains('max') && value is UploadedFile;
  }

  void _addFileValidationParameters(
    Map<String, dynamic> parameters,
    String messageKey,
    dynamic value,
    String? arg,
  ) {
    if (arg != null && messageKey.contains('max')) {
      final sizeLimit = int.tryParse(arg);
      if (sizeLimit != null) {
        parameters['max'] = (sizeLimit / 1024).round(); // Convert to KB
      }
    }

    // Add current file size
    if (value is UploadedFile) {
      parameters['current'] = (value.size / 1024).round();
      parameters['filename'] = value.filename;
    }
  }
}

/// Extension methods for common validation patterns
extension ValidatorHelpers on AdvancedInputValidator {
  /// Quick method to validate file uploads
  static Map<String, String> fileUploadRules({
    bool required = true,
    bool nullable = false,
    List<String> allowedMimes = const [],
    int? maxSizeKB,
    bool multiple = false,
  }) {
    final rules = <String>[];
    
    if (nullable) rules.add('nullable');
    if (required && !nullable) rules.add('required');
    
    if (multiple) {
      rules.add('array');
      
      final itemRules = <String>['file'];
      if (allowedMimes.isNotEmpty) {
        itemRules.add('mimes:${allowedMimes.join(',')}');
      }
      if (maxSizeKB != null) {
        itemRules.add('max:$maxSizeKB');
      }
      
      return {
        'attachments': rules.join('|'),
        'attachments.*': itemRules.join('|'),
      };
    } else {
      rules.add('file');
      if (allowedMimes.isNotEmpty) {
        rules.add('mimes:${allowedMimes.join(',')}');
      }
      if (maxSizeKB != null) {
        rules.add('max:$maxSizeKB');
      }
      
      return {'attachment': rules.join('|')};
    }
  }

  /// Quick method to validate array of specific types
  static Map<String, String> arrayRules(
    String fieldName,
    String itemRules, {
    bool nullable = false,
    bool required = true,
    int? minItems,
    int? maxItems,
  }) {
    final rules = <String>[];
    
    if (nullable) rules.add('nullable');
    if (required && !nullable) rules.add('required');
    
    rules.add('array');
    if (minItems != null) rules.add('min_items:$minItems');
    if (maxItems != null) rules.add('max_items:$maxItems');
    
    return {
      fieldName: rules.join('|'),
      '$fieldName.*': itemRules,
    };
  }
}
