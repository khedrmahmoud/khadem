import 'dart:async';

import '../../../support/exceptions/validation_exception.dart';
import '../../validation/validator.dart';
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
    final validator = Validator(input, rules);

    if (!validator.passes()) {
      throw ValidationException(validator.errors);
    }

    return input;
  }

  /// Validates specific input data against rules.
  Map<String, dynamic> validateData(Map<String, dynamic> data, Map<String, String> rules) {
    final validator = Validator(data, rules);

    if (!validator.passes()) {
      throw ValidationException(validator.errors);
    }

    return data;
  }
}
