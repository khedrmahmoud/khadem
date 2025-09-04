import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Handles parsing of HTTP request bodies.
/// Supports JSON, form data, and other content types.
class RequestBodyParser {
  final HttpRequest _raw;
  Map<String, dynamic>? _parsedBody;

  RequestBodyParser(this._raw);

  /// Parses and returns the request body as a Map.
  /// Supports `application/json` and `application/x-www-form-urlencoded`.
  Future<Map<String, dynamic>> parseBody() async {
    if (_parsedBody != null) return _parsedBody!;

    final contentType = _raw.headers.contentType?.mimeType;
    final bodyString = await utf8.decoder.bind(_raw).join();

    if (contentType == 'application/json') {
      _parsedBody = _parseJsonBody(bodyString);
    } else if (contentType == 'application/x-www-form-urlencoded') {
      _parsedBody = _parseFormBody(bodyString);
    } else {
      _parsedBody = {};
    }

    return _parsedBody!;
  }

  /// Parses JSON body content.
  Map<String, dynamic> _parseJsonBody(String bodyString) {
    try {
      return jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Invalid JSON format in request body');
    }
  }

  /// Parses form-encoded body content.
  Map<String, dynamic> _parseFormBody(String bodyString) {
    return Uri.splitQueryString(bodyString);
  }

  /// Clears the cached parsed body.
  void clearCache() {
    _parsedBody = null;
  }
}
