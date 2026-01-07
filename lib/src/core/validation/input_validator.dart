import 'dart:async';
import '../../contracts/validation/rule.dart';
import '../../support/exceptions/validation_exception.dart';
import '../http/request/uploaded_file.dart';
import '../lang/lang.dart';
import 'rule_registry.dart';

class _RuleItem {
  final Rule rule;
  final List<String> args;
  final String name;

  _RuleItem(this.rule, this.name, [this.args = const []]);
}

/// Example: 'attachments': 'nullable|array', 'attachments.*': 'file|max:5120'
class InputValidator {
  final Map<String, dynamic> data;
  final Map<String, dynamic> rules; // Changed to dynamic to support List<Rule>
  final Map<String, String> customMessages;
  final Map<String, List<String>> errors = {};

  InputValidator(
    this.data,
    this.rules, {
    this.customMessages = const {},
  });

  Future<bool> passes() async {
    errors.clear();

    // Process all rules, including nested ones
    // We collect all validation futures to run them in parallel where possible
    final validationFutures = <Future<void>>[];

    for (final entry in rules.entries) {
      final fieldPattern = entry.key;
      final ruleDefinition = entry.value;

      if (fieldPattern.contains('*')) {
        // Handle nested/wildcard validation (e.g., attachments.*)
        validationFutures
            .add(_validateNestedField(fieldPattern, ruleDefinition));
      } else {
        // Handle regular field validation
        validationFutures.add(_validateField(fieldPattern, ruleDefinition));
      }
    }

    await Future.wait(validationFutures);

    return errors.isEmpty;
  }

  Future<void> validate() async {
    if (!await passes()) {
      throw ValidationException(errors);
    }
  }

  Future<void> _validateField(String field, dynamic ruleDefinition) async {
    final value = _getFieldValue(field);
    final ruleItems = _normalizeRules(ruleDefinition);
    final shouldBail = _hasBail(ruleDefinition);

    // Check if field is nullable and null - if so, skip validation
    if (_isNullableAndNull(ruleItems, value)) {
      return;
    }

    for (final item in ruleItems) {
      final context = ValidationContext(
        attribute: field,
        value: value,
        parameters: item.args,
        data: data,
      );

      final isValid = await item.rule.passes(context);

      if (!isValid) {
        if (!errors.containsKey(field)) {
          errors[field] = [];
        }

        final messageKey = item.rule.message(context);
        errors[field]!.add(
          _formatErrorMessage(
            messageKey,
            field,
            item.args,
            value,
            item.name,
          ),
        );

        if (shouldBail) {
          break; // Stop at first error for this field if bail is set
        }
      }
    }
  }

  bool _hasBail(dynamic ruleDefinition) {
    if (ruleDefinition is String) {
      return ruleDefinition.split('|').contains('bail');
    } else if (ruleDefinition is List) {
      return ruleDefinition.contains('bail');
    }
    return false;
  }

  Future<void> _validateNestedField(
      String fieldPattern, dynamic ruleDefinition,) async {
    // Convert pattern like "attachments.*" to actual field paths
    final fieldPaths = _expandFieldPattern(fieldPattern);
    final futures = <Future<void>>[];

    for (final fieldPath in fieldPaths) {
      futures.add(_validateField(fieldPath, ruleDefinition));
    }

    await Future.wait(futures);
  }

  List<_RuleItem> _normalizeRules(dynamic ruleDefinition) {
    final items = <_RuleItem>[];

    if (ruleDefinition is String) {
      // 'required|max:50'
      final parts = ruleDefinition.split('|');
      for (final part in parts) {
        if (part == 'bail') continue;
        items.add(_parseStringRule(part));
      }
    } else if (ruleDefinition is List) {
      // ['required', MaxRule(50), 'email']
      for (final part in ruleDefinition) {
        if (part == 'bail') continue;
        if (part is String) {
          // Handle mixed string rules in list: ['required|email', MaxRule(50)]
          if (part.contains('|')) {
            final subParts = part.split('|');
            for (final subPart in subParts) {
              if (subPart == 'bail') continue;
              items.add(_parseStringRule(subPart));
            }
          } else {
            items.add(_parseStringRule(part));
          }
        } else if (part is Rule) {
          items.add(_RuleItem(part, 'custom', []));
        }
      }
    } else if (ruleDefinition is Rule) {
      items.add(_RuleItem(ruleDefinition, 'custom', []));
    }
    return items;
  }

  _RuleItem _parseStringRule(String ruleString) {
    final segments = ruleString.split(':');
    final ruleName = segments[0];
    final ruleArgs = segments.length > 1 ? segments[1].split(',') : <String>[];

    final rule = ValidationRuleRepository.resolve(ruleName);
    if (rule == null) {
      // Fallback or throw? For now, maybe a dummy rule that always passes or logs warning
      // But better to be strict.
      // We can't throw easily here without breaking flow, but let's assume it exists.
      // If not found, we might want to throw an exception to the developer.
      throw Exception("Validation rule '$ruleName' not found.");
    }
    return _RuleItem(rule, ruleName, ruleArgs);
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
    final paths = <String>[];

    // Handle patterns like "documents.*.title" or "users.*.profile.email"
    final parts = pattern.split('.*');
    if (parts.length >= 2) {
      final basePattern = parts[0]; // e.g., "documents"
      final remainingPath = parts.sublist(1).join('.*'); // e.g., ".title"

      final baseValue = _getFieldValue(basePattern);

      if (baseValue is List) {
        for (int i = 0; i < baseValue.length; i++) {
          final expandedPath = '$basePattern.$i$remainingPath';
          paths.add(expandedPath);
        }
      } else if (baseValue is Map) {
        for (final key in baseValue.keys) {
          final expandedPath = '$basePattern.$key$remainingPath';
          paths.add(expandedPath);
        }
      }
    } else {
      // Fallback: return pattern as-is for unsupported patterns
      paths.add(pattern);
    }

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

  bool _isNullableAndNull(List<_RuleItem> items, dynamic value) {
    final hasNullable = items.any((item) => item.name == 'nullable');
    return hasNullable && value == null;
  }

  String _formatErrorMessage(
    String messageKey,
    String field,
    List<String> args,
    dynamic value, [
    String? ruleName,
  ]) {
    // Check if there's a custom message for this field and rule
    if (ruleName != null) {
      final customKey = '$field.$ruleName';
      if (customMessages.containsKey(customKey)) {
        return customMessages[customKey]!;
      }
    }

    final parameters = <String, dynamic>{
      'field': Lang.getField(field),
      'arg': args.isNotEmpty ? args.first : '',
      'args': args.join(','),
    };

    for (var i = 0; i < args.length; i++) {
      parameters['arg$i'] = args[i];
    }

    // Add file-specific parameters for better error messages
    if (_isFileValidationContext(messageKey, value)) {
      _addFileValidationParameters(parameters, messageKey, value, args);
    }

    return Lang.t(messageKey, parameters: parameters, namespace: 'validation');
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
    List<String> args,
  ) {
    final arg = args.isNotEmpty ? args.first : null;

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
extension ValidatorHelpers on InputValidator {
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
