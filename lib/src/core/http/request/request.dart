import 'dart:async';
import 'dart:io';

import 'package:khadem/src/support/helpers/cookie.dart';

import 'body_parser.dart';
import 'request_headers.dart';
import 'request_input.dart';
import 'request_metadata.dart';
import 'request_params.dart';
import 'request_session.dart';
import 'request_validator.dart';
import 'uploaded_file.dart';

/// Represents an HTTP request within the Khadem framework.
///
/// Provides a clean interface for accessing request data with:
/// - Single responsibility principle for each component
/// - Fast, optimized accessors with caching
/// - Type-safe parameter handling
/// - Comprehensive metadata access
/// - Easy-to-use input helpers
class Request {
  final HttpRequest _raw;

  late final BodyParser _bodyParser;
  late final RequestValidator _validator;
  late final RequestHeaders _headers;
  late final RequestParams _params;
  late final RequestSession _session;
  late final RequestMetadata _metadata;
  late final RequestInput _input;

  Request(this._raw) {
    _bodyParser = BodyParser(_raw);
    _headers = RequestHeaders(_raw.headers);
    _params = RequestParams(<String, String>{}, <String, dynamic>{});
    _validator = RequestValidator(_bodyParser);
    _session = RequestSession(_raw);
    _metadata = RequestMetadata(_raw);
    _input = RequestInput(_bodyParser, _raw.uri.queryParameters);
  }

  // ===== Core Accessors =====

  /// HTTP method (GET, POST, PUT, etc.)
  String get method => _metadata.method;

  /// Request path (/api/users)
  String get path => _metadata.path;

  /// Full request URI
  Uri get uri => _metadata.uri;

  /// Raw HttpRequest from Dart SDK
  HttpRequest get raw => _raw;

  /// Query parameters
  Map<String, String> get query => _metadata.query;

  /// Client IP address (handles proxies)
  String get ip => _metadata.ip;

  /// Request port
  int? get port => _metadata.port;

  // ===== Component Accessors =====

  /// Access to body parsing
  BodyParser get bodyParser => _bodyParser;

  /// Access to validation
  RequestValidator get validator => _validator;

  /// Access to headers
  RequestHeaders get headers => _headers;

  /// Access to parameters
  RequestParams get params => _params;

  /// Access to session
  RequestSession get session => _session;

  /// Access to metadata
  RequestMetadata get metadata => _metadata;

  /// Access to input helper
  RequestInput get input => _input;

  // ===== Body & Input Access =====

  /// Gets parsed body
  Future<Map<String, dynamic>> get body => _bodyParser.parse();

  /// Gets all input (body + query) - shortcut
  Map<String, dynamic> get all => _input.all();

  /// Gets input value from body or query
  dynamic get(String key, [dynamic defaultValue]) =>
      _input.get(key, defaultValue);

  /// Gets typed input value
  T? getTyped<T>(String key, [T? defaultValue]) =>
      _input.typed<T>(key, defaultValue);

  /// Gets string input
  String? getString(String key, [String? defaultValue]) =>
      _input.string(key, defaultValue);

  /// Gets integer input
  int? getInt(String key, [int? defaultValue]) =>
      _input.integer(key, defaultValue);

  /// Gets double input
  double? getDouble(String key, [double? defaultValue]) =>
      _input.doubleValue(key, defaultValue);

  /// Gets boolean input
  bool getBoolean(String key, [bool defaultValue = false]) =>
      _input.boolean(key, defaultValue);

  /// Gets list input
  List<T>? getList<T>(String key) => _input.list<T>(key);

  /// Gets map input
  Map<String, dynamic>? getMap(String key) => _input.map(key);

  /// Checks if input key exists
  bool hasInput(String key) => _input.has(key);

  /// Checks if multiple input keys exist
  bool hasInputAll(List<String> keys) => _input.hasAll(keys);

  /// Checks if any input key exists
  bool hasInputAny(List<String> keys) => _input.hasAny(keys);

  /// Gets only specified input keys
  Map<String, dynamic> only(List<String> keys) => _input.only(keys);

  /// Gets all input except specified keys
  Map<String, dynamic> except(List<String> keys) => _input.except(keys);

  // ===== File Access =====

  /// Gets all uploaded files
  Map<String, UploadedFile>? get files => _bodyParser.files;

  /// Gets a specific uploaded file
  UploadedFile? file(String fieldName) => _bodyParser.file(fieldName);

  /// Gets all files with a field name
  List<UploadedFile> filesByName(String fieldName) =>
      _bodyParser.filesByName(fieldName);

  /// Checks if file was uploaded
  bool hasFile(String fieldName) => _bodyParser.hasFile(fieldName);

  /// Gets first file by field name
  UploadedFile? firstFile(String fieldName) => _bodyParser.firstFile(fieldName);

  // ===== Validation =====

  /// Validates request body
  Future<Map<String, dynamic>> validate(
    Map<String, String> rules, {
    Map<String, String>? messages,
  }) =>
      _validator.validateBody(rules, messages: messages);

  /// Validates specific data
  Map<String, dynamic> validateData(
    Map<String, dynamic> data,
    Map<String, String> rules,
  ) =>
      _validator.validateData(data, rules);

  // ===== Path Parameters =====

  /// Gets a path parameter
  String? param(String key) => _params.param(key);

  /// Gets path parameter with default
  String paramOr(String key, String defaultValue) =>
      _params.paramOr(key, defaultValue);

  /// Gets typed path parameter
  T? paramTyped<T>(String key) => _params.paramTyped<T>(key);

  /// Gets path parameter as int
  int? paramInt(String key) => _params.paramInt(key);

  /// Gets path parameter as double
  double? paramDouble(String key) => _params.paramDouble(key);

  /// Gets path parameter as bool
  bool paramBool(String key) => _params.paramBool(key);

  /// Sets a path parameter
  void setParam(String key, String value) => _params.setParam(key, value);

  /// Checks if path parameter exists
  bool hasParam(String key) => _params.hasParam(key);

  /// Gets all path parameters
  Map<String, String> get allParams => _params.all;

  // ===== Custom Attributes =====

  /// Gets a custom attribute
  T? attribute<T>(String key) => _params.attribute<T>(key);

  /// Gets attribute with default
  T attributeOr<T>(String key, T defaultValue) =>
      _params.attributeOr<T>(key, defaultValue);

  /// Sets a custom attribute
  void setAttribute(String key, dynamic value) =>
      _params.setAttribute(key, value);

  /// Checks if attribute exists
  bool hasAttribute(String key) => _params.hasAttribute(key);

  /// Gets all attributes
  Map<String, dynamic> get allAttributes => _params.attributes;

  // ===== Headers =====

  /// Gets a header value
  String? header(String name) => _headers.get(name);

  /// Gets all header values
  List<String>? headerAll(String name) => _headers.getAll(name);

  /// Checks if header exists
  bool hasHeader(String name) => _headers.has(name);

  /// Gets Content-Type header
  String? get contentType => _headers.contentType;

  /// Gets User-Agent header
  String? get userAgent => _headers.userAgent;

  /// Gets Accept header
  String? get accept => _headers.accept;

  /// Gets Authorization header
  String? get authorization => _headers.authorization;

  /// Gets all headers as map
  Map<String, String> get allHeaders => _headers.toMap();

  // ===== Request Metadata =====

  /// Checks if request is HTTPS
  bool get isSecure => _metadata.isSecure;

  /// Checks if request is AJAX/XHR
  bool get isAjax => _metadata.isAjax;

  /// Checks if request wants JSON
  bool get wantsJson => _metadata.wantsJson;

  /// Gets protocol version
  String get protocol => _metadata.protocol;

  /// Gets host name
  String? get host => _metadata.host;

  /// Gets origin (CORS)
  String? get origin => _metadata.origin;

  /// Gets referrer
  String? get referrer => _metadata.referrer;

  /// Checks if method matches
  bool isMethod(String method) => _metadata.isMethod(method);

  /// Checks if GET
  bool get isGet => _metadata.isGet;

  /// Checks if POST
  bool get isPost => _metadata.isPost;

  /// Checks if PUT
  bool get isPut => _metadata.isPut;

  /// Checks if PATCH
  bool get isPatch => _metadata.isPatch;

  /// Checks if DELETE
  bool get isDelete => _metadata.isDelete;

  // ===== Cookies =====

  /// Gets all cookies
  Map<String, String> get cookies => CookieHelper(_raw).all;

  /// Gets a cookie value
  String? cookie(String name) => CookieHelper(_raw).get(name);

  /// Checks if cookie exists
  bool hasCookie(String name) => CookieHelper(_raw).has(name);

  /// Gets CSRF token cookie
  String? get csrfToken => cookie('csrf_token');

  /// Gets remember token cookie
  String? get rememberToken => cookie('remember_token');

  // ===== Session =====

  /// Gets session ID
  String get sessionId => _session.sessionId;

  /// Gets a session value
  dynamic getSessionValue(String key) => _session.get(key);

  /// Sets a session value
  void setSessionValue(String key, dynamic value) => _session.set(key, value);

  /// Checks if session key exists
  bool hasSessionValue(String key) => _session.has(key);

  /// Removes a session value
  void removeSessionValue(String key) => _session.remove(key);

  /// Gets all session data
  Map<String, dynamic> get allSession => _session.getAllData();

  // ===== Cleanup =====

  /// Cleans up request resources (temp files, etc.)
  Future<void> cleanup() async {
    await _bodyParser.cleanup();
  }
}
