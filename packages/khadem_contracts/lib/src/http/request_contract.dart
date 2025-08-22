import 'dart:io';

/// HTTP request contract that defines the required methods for request handling
abstract class RequestContract {
  /// Get the request method (GET, POST, etc.)
  String get method;

  /// Get the request path
  String get path;

  /// Get the request query parameters
  Map<String, String> get query;

  /// Get the request headers
  Map<String, String> get headers;

  /// Get the request body
  dynamic get body;

  /// Get a request header value
  String? header(String name);

  /// Get a query parameter value
  String? queryParam(String name);

  /// Get an input value from body or query
  T? input<T>(String name);

  /// Get all input values
  Map<String, dynamic> get allInput;

  /// Get uploaded files
  List<File> get files;

  /// Get the client IP address
  String get ip;

  /// Get the request locale
  String get locale;

  /// Check if request accepts a specific content type
  bool accepts(String contentType);

  /// Check if request wants JSON response
  bool get wantsJson;
}
