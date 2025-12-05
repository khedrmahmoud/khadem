import '../../support/exceptions/validation_exception.dart';
import '../http/request/uploaded_file.dart';
import '../lang/lang.dart';
import 'rule_registry.dart';

@Deprecated('Use InputValidator instead')
class Validator {
  final Map<String, dynamic> data;
  final Map<String, String> rules;
  final Map<String, String> errors = {};

  Validator(this.data, this.rules);

  bool passes() {
    for (final entry in rules.entries) {
      final field = entry.key;
      final ruleString = entry.value;
      final value = data[field];
      final ruleParts = ruleString.split('|');

      // Check if field is nullable and null - if so, skip all validation
      final hasNullableRule =
          ruleParts.any((part) => part.split(':')[0] == 'nullable');
      if (hasNullableRule && value == null) {
        continue; // Skip validation for this nullable field
      }

      for (final part in ruleParts) {
        final segments = part.split(':');
        final name = segments[0];
        final arg = segments.length > 1 ? segments[1] : null;

        final rule = ValidationRuleRepository.resolve(name);
        if (rule != null) {
          final messageKey = rule.validate(field, value, arg, data: data);
          if (messageKey != null) {
            final parameters = <String, dynamic>{'field': field, 'arg': arg};

            // Handle file validation specific parameters
            if (_isFileValidationRule(name) && value != null) {
              _addFileValidationParameters(parameters, name, value, arg);
            }

            errors[field] = Lang.t(messageKey, parameters: parameters);
            break;
          }
        }
      }
    }

    return errors.isEmpty;
  }

  void validate() {
    if (!passes()) {
      throw ValidationException(errors);
    }
  }

  bool _isFileValidationRule(String ruleName) {
    return ['file', 'image', 'mimes', 'max', 'min'].contains(ruleName);
  }

  void _addFileValidationParameters(
    Map<String, dynamic> parameters,
    String ruleName,
    dynamic value,
    String? arg,
  ) {
    if (arg != null && (ruleName == 'max' || ruleName == 'min')) {
      final sizeLimit = int.tryParse(arg);
      if (sizeLimit != null) {
        final sizeLimitKB = (sizeLimit / 1024).round();
        parameters['max'] = sizeLimitKB;
        parameters['min'] = sizeLimitKB;
      }
    }

    // Add current file size if we have a file
    if (value is UploadedFile) {
      final currentSizeKB = (value.size / 1024).round();
      parameters['current'] = currentSizeKB;
    } else if (value is List<UploadedFile>) {
      // For multiple files, we can't easily determine which file failed,
      // so we'll use the first file's size as an approximation
      if (value.isNotEmpty) {
        final currentSizeKB = (value.first.size / 1024).round();
        parameters['current'] = currentSizeKB;
      }
    }
  }
}
