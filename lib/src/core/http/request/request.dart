import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../support/exceptions/validation_exception.dart';
import '../../validation/validator.dart';

/// Represents an HTTP request within the Khadem framework.
///
/// Provides helpers for parsing the body, retrieving headers,
/// query parameters, path params, and validating input.
class Request {
  final HttpRequest _raw;

  /// Path parameters extracted from the router.
  Map<String, String> params = {};
  
  String? param(String key) {
    return params[key];
  }

  /// Custom runtime attributes like `user`, `session`, etc.
  final Map<String, dynamic> attributes = {};

  /// Cached parsed body.
  Map<String, dynamic>? _parsedBody;

  Request(this._raw);

  /// HTTP method (GET, POST, etc.)
  String get method => _raw.method;

  /// URI path (/api/users)
  String get path => _raw.uri.path;

  /// Full request URI
  Uri get uri => _raw.uri;

  /// Raw HttpRequest from Dart SDK
  HttpRequest get raw => _raw;

  /// HTTP headers
  HttpHeaders get headers => _raw.headers;

  /// Request query parameters
  Map<String, String> get query => _raw.uri.queryParameters;

  /// Parses and returns the request body as a Map.
  ///
  /// Supports `application/json` and `application/x-www-form-urlencoded`.
  Future<Map<String, dynamic>> get body async {
    if (_parsedBody != null) return _parsedBody!;

    final contentType = _raw.headers.contentType?.mimeType;
    final bodyString = await utf8.decoder.bind(_raw).join();

    if (contentType == 'application/json') {
      try {
        _parsedBody = jsonDecode(bodyString) as Map<String, dynamic>;
      } catch (_) {
        throw ValidationException({'body': 'Invalid JSON format'});
      }
    } else if (contentType == 'application/x-www-form-urlencoded') {
      _parsedBody = Uri.splitQueryString(bodyString);
    } else {
      _parsedBody = {};
    }

    return _parsedBody!;
  }

  /// Validates the request body input against the given rules.
  ///
  /// Throws [ValidationException] if validation fails.
  /// Validates the request body input against the specified rules.
  ///
  /// Uses the Validator class to ensure that the input data adheres to the
  /// provided validation rules. If validation fails, a [ValidationException]
  /// is thrown containing the validation errors. If validation passes, the
  /// input data is returned.
  ///
  /// Args:
  ///   rules ([Map<String, String>]): A map of validation rules to apply to the
  ///   request body input.
  ///
  /// Returns:
  ///   [Future<Map<String, dynamic>>]: A future that completes with the validated
  ///   input data if validation is successful.
  Future<Map<String, dynamic>> validate(Map<String, String> rules) async {
    final input = await body;
    final validator = Validator(input, rules);

    if (!validator.passes()) {
      return Future.error(ValidationException(validator.errors));
    }

    return input;
  }

  /// Returns the currently authenticated user (if any).
  Map<String, dynamic>? get user => attributes['user'] as Map<String, dynamic>?;

  /// Returns the ID of the authenticated user (if available).
  dynamic get userId => user?['id'];

  /// Returns true if a user is authenticated.
  bool get isAuthenticated => user != null;

  /// Returns true if no user is authenticated.
  bool get isGuest => user == null;
}
