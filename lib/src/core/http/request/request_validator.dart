import 'dart:async';

import 'package:khadem/src/core/validation/enhanced_validator.dart';

import '../../../support/exceptions/validation_exception.dart';
import 'request_body_parser.dart';

/// Handles validation of request data against specified rules.
class RequestValidator {
  final RequestBodyParser _bodyParser;

  RequestValidator(this._bodyParser);

  /// Validates the request body input against the given rules.
  ///
  /// Throws [ValidationException] if validation fails.
  /// Returns the validated input data if validation passes.
  Future<Map<String, dynamic>> validateBody(Map<String, String> rules) async {
    final input = await _bodyParser.parseBody();

    // Merge uploaded files into the input data for validation
    if (_bodyParser.files != null) {
      input.addAll(_bodyParser.files as Map<String, dynamic>);
    }

    final validator = AdvancedInputValidator(input, rules);

    if (!validator.passes()) {
      throw ValidationException(validator.errors);
    }

    // Return only the validated data that are in the rules
    return {
      for (var key in rules.keys)
        if (input.containsKey(key)) key: input[key]
    };
  }

  /// Validates specific input data against rules.
  Map<String, dynamic> validateData(
      Map<String, dynamic> data, Map<String, String> rules) {
    // If no files are provided in data, try to get them from the body parser
    final validationData = Map<String, dynamic>.from(data);
    if (_bodyParser.files != null && !validationData.containsKey('files')) {
      validationData.addAll(_bodyParser.files as Map<String, dynamic>);
    }

    final validator = AdvancedInputValidator(validationData, rules);

    if (!validator.passes()) {
      throw ValidationException(validator.errors);
    }

    // Return only the validated data that are in the rules
    return {
      for (var key in rules.keys)
        if (validationData.containsKey(key)) key: validationData[key]
    };
  }
}
