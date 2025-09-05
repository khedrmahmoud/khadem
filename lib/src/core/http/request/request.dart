import 'dart:async';
import 'dart:io';

import 'request_auth.dart';
import 'request_body_parser.dart';
import 'request_headers.dart';
import 'request_params.dart';
import 'request_validator.dart';

/// Represents an HTTP request within the Khadem framework.
///
/// This class provides a clean, well-organized interface for handling HTTP requests
/// with proper separation of concerns. It delegates specific functionality to
/// specialized components for better maintainability and testability.
///
/// Key features:
/// - HTTP method and URI access
/// - Header management
/// - Body parsing and validation
/// - Parameter handling
/// - Authentication state
/// - Custom attributes
class Request {
  final HttpRequest _raw;

  late final RequestBodyParser _bodyParser;
  late final RequestValidator _validator;
  late final RequestAuth _auth;
  late final RequestHeaders _headers;
  late final RequestParams _params;

  Request(this._raw) {
    _bodyParser = RequestBodyParser(_raw);
    _headers = RequestHeaders(_raw.headers);
    _params = RequestParams(<String, String>{}, <String, dynamic>{});
    _auth = RequestAuth(_params.attributes);
    _validator = RequestValidator(_bodyParser);
  }

  /// HTTP method (GET, POST, etc.)
  String get method => _raw.method;

  /// URI path (/api/users)
  String get path => _raw.uri.path;

  /// Full request URI
  Uri get uri => _raw.uri;

  /// Raw HttpRequest from Dart SDK
  HttpRequest get raw => _raw;

  /// Request query parameters
  Map<String, String> get query => _raw.uri.queryParameters;

  /// Access to body parsing functionality
  RequestBodyParser get bodyParser => _bodyParser;

  /// Access to validation functionality
  RequestValidator get validator => _validator;

  /// Access to authentication functionality
  RequestAuth get auth => _auth;

  /// Access to header functionality
  RequestHeaders get headers => _headers;

  /// Access to parameter functionality
  RequestParams get params => _params;

  /// Parses and returns the request body as a Map.
  /// Shortcut for bodyParser.parseBody()
  Future<Map<String, dynamic>> get body => _bodyParser.parseBody();

  /// Gets a specific input value from the parsed body.
   dynamic input(String key, [dynamic defaultValue]) =>
      _bodyParser.input(key, defaultValue);
  
  /// check if has field
  /// Checks if the request body contains the specified field.
  bool has(String key) => _bodyParser.has(key);

  /// Gets uploaded files from the request.
  /// Shortcut for bodyParser.files
  Map<String, dynamic>? get files => _bodyParser.files;

  /// Gets a specific uploaded file by field name.
  /// Shortcut for bodyParser.file()
  UploadedFile? file(String fieldName) => _bodyParser.file(fieldName);

  /// Gets all files with a specific field name (for multiple file uploads).
  /// Shortcut for bodyParser.filesByName()
  List<UploadedFile> filesByName(String fieldName) =>
      _bodyParser.filesByName(fieldName);

  /// Checks if a file was uploaded with the given field name.
  /// Shortcut for bodyParser.hasFile()
  bool hasFile(String fieldName) => _bodyParser.hasFile(fieldName);

  /// Gets the first file from multiple files with the same name.
  /// Shortcut for bodyParser.firstFile()
  UploadedFile? firstFile(String fieldName) => _bodyParser.firstFile(fieldName);

  /// Validates the request body input against the given rules.
  /// Shortcut for validator.validateBody()
  Future<Map<String, dynamic>> validate(Map<String, String> rules) =>
      _validator.validateBody(rules);

  /// Validates specific input data against rules.
  /// Shortcut for validator.validateData()
  Map<String, dynamic> validateData(
    Map<String, dynamic> data,
    Map<String, String> rules,
  ) =>
      _validator.validateData(data, rules);

  /// Gets a path parameter by key.
  /// Shortcut for params.param()
  String? param(String key) => _params.param(key);

  /// Sets a path parameter.
  /// Shortcut for params.setParam()
  void setParam(String key, String value) => _params.setParam(key, value);

  /// Gets a custom attribute by key.
  /// Shortcut for params.attribute()
  T? attribute<T>(String key) => _params.attribute<T>(key);

  /// Sets a custom attribute.
  /// Shortcut for params.setAttribute()
  void setAttribute(String key, dynamic value) =>
      _params.setAttribute(key, value);

  /// Returns the currently authenticated user (if any).
  /// Shortcut for auth.user
  Map<String, dynamic>? get user => _auth.user;

  /// Returns the ID of the authenticated user (if available).
  /// Shortcut for auth.userId
  dynamic get userId => _auth.userId;

  /// Returns true if a user is authenticated.
  /// Shortcut for auth.isAuthenticated
  bool get isAuthenticated => _auth.isAuthenticated;

  /// Returns true if no user is authenticated.
  /// Shortcut for auth.isGuest
  bool get isGuest => _auth.isGuest;

  /// Sets the authenticated user.
  /// Shortcut for auth.setUser()
  void setUser(Map<String, dynamic> userData) => _auth.setUser(userData);

  /// Clears the authenticated user.
  /// Shortcut for auth.clearUser()
  void clearUser() => _auth.clearUser();

  /// Checks if the user has a specific role.
  /// Shortcut for auth.hasRole()
  bool hasRole(String role) => _auth.hasRole(role);

  /// Checks if the user has any of the specified roles.
  /// Shortcut for auth.hasAnyRole()
  bool hasAnyRole(List<String> roles) => _auth.hasAnyRole(roles);

  /// Checks if the user has all of the specified roles.
  /// Shortcut for auth.hasAllRoles()
  bool hasAllRoles(List<String> roles) => _auth.hasAllRoles(roles);

  /// Gets a header value by name.
  /// Shortcut for headers.header()
  String? header(String name) => _headers.header(name);

  /// Checks if a header exists.
  /// Shortcut for headers.hasHeader()
  bool hasHeader(String name) => _headers.hasHeader(name);

  /// Gets the Content-Type header.
  /// Shortcut for headers.contentType
  String? get contentType => _headers.contentType;

  /// Gets the User-Agent header.
  /// Shortcut for headers.userAgent
  String? get userAgent => _headers.userAgent;

  /// Checks if the request accepts JSON responses.
  /// Shortcut for headers.acceptsJson()
  bool acceptsJson() => _headers.acceptsJson();

  /// Checks if the request accepts HTML responses.
  /// Shortcut for headers.acceptsHtml()
  bool acceptsHtml() => _headers.acceptsHtml();

  /// Checks if the request is from XMLHttpRequest (AJAX).
  /// Shortcut for headers.isAjax()
  bool isAjax() => _headers.isAjax();
}
