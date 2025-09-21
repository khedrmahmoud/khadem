import 'dart:async';
import 'dart:io';

import 'package:khadem/src/modules/auth/services/web_auth_service.dart';
import 'package:khadem/src/support/helpers/cookie.dart';

import 'request_auth.dart';
import 'request_body_parser.dart';
import 'request_headers.dart';
import 'request_params.dart';
import 'request_session.dart';
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
  late final RequestSession _session;

  Request(this._raw) {
    _bodyParser = RequestBodyParser(_raw);
    _headers = RequestHeaders(_raw.headers);
    _params = RequestParams(<String, String>{}, <String, dynamic>{});
    _auth = RequestAuth(_params.attributes);
    _validator = RequestValidator(_bodyParser);
    _session = RequestSession(_raw);
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

  /// Client IP address
  String get ip => _raw.connectionInfo?.remoteAddress.address ?? 'unknown';

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

  /// Cookie management
  CookieHelper get cookieHandler => CookieHelper(_raw);

  /// Shortcut for accessing cookies from the raw HttpRequest
  Map<String, String> get cookies => cookieHandler.all;

  /// Gets a specific cookie value by name.
  String? cookie(String name) => cookieHandler.get(name);

  /// Gets a specific cookie object by name.
  Cookie? cookieObject(String name) => cookieHandler.getCookie(name);

  /// Gets the remember token cookie value.
  String? get rememberToken => cookieHandler.get('remember_token');

  /// Gets the CSRF token cookie value.
  String? get csrfToken => cookieHandler.get('csrf_token');

  /// Checks if a remember token cookie is present.
  bool hasRememberToken() => rememberToken != null;

  /// Checks if a CSRF token cookie is present.
  bool hasCsrfToken() => csrfToken != null;

  /// Checks if a specific cookie is present.
  bool hasCookie(String name) => cookieHandler.has(name);

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

  /// Manages HTTP sessions
  RequestSession get session => _session;

  /// Gets the session ID.
  String get sessionId => _session.sessionId;

  /// Gets all session keys.
  Iterable<dynamic> get sessionKeys => _session.sessionKeys;

  /// Checks if the session is empty.
  bool get isSessionEmpty => _session.isSessionEmpty;

  /// Gets the number of items in the session.
  int get sessionLength => _session.sessionLength;

  /// Destroys the current session.
  void destroySession() => _session.destroy();

  /// Gets a value from the session by key.
  dynamic getSession(String key) => _session.get(key);

  /// Sets a value in the session.
  void setSession(String key, dynamic value) => _session.set(key, value);

  /// Checks if a key exists in the session.
  bool hasSession(String key) => _session.has(key);

  /// Removes a key from the session.
  void removeSession(String key) => _session.remove(key);

  /// Clears all session data.
  void clearSession() => _session.clear();

  /// Sets multiple values in the session at once.
  void setMultipleSessions(Map<String, dynamic> data) =>
      _session.setMultiple(data);

  /// Gets a typed value from the session, with optional default.
  T? getSessionTyped<T>(String key, [T? defaultValue]) =>
      _session.getTyped<T>(key, defaultValue);

  /// Flashes a value to the session (temporary, removed after next access).
  void flashSession(String key, dynamic value) => _session.flash(key, value);

  /// Retrieves and removes a flashed value from the session.
  dynamic pullSession(String key) => _session.pull(key);

  /// Regenerates the session ID for security.
  void regenerateSessionId() => _session.regenerateId();

  /// Gets all flashed data and clears them.
  Map<String, dynamic> getFlashedSessionData() => _session.getFlashedData();

  /// Checks if the session has any flashed data.
  bool hasFlashedSessionData() => _session.hasFlashedData();

  /// Sets the session timeout.
  void setSessionTimeout(Duration timeout) => _session.setTimeout(timeout);

  /// Gets the session timeout if set.
  Duration? getSessionTimeout() => _session.getTimeout();

  /// Validates the session.
  bool isSessionValid() => _session.isValid();

  /// Touches the session to update last access time.
  void touchSession() => _session.touch();

  /// Gets the last access time of the session.
  DateTime? getSessionLastAccess() => _session.getLastAccess();

  /// Gets the session creation time.
  DateTime? getSessionCreatedAt() => _session.getCreatedAt();

  /// Checks if the session should be regenerated.
  bool shouldRegenerateSession({Duration maxAge = const Duration(hours: 1)}) =>
      _session.shouldRegenerate(maxAge: maxAge);

  /// Forces session invalidation.
  void invalidateSession() => _session.invalidate();

  /// Checks if the session has been invalidated.
  bool isSessionInvalidated() => _session.isInvalidated();

  /// Gets session statistics.
  Map<String, dynamic> getSessionStats() => _session.getStats();

  /// Cleans up expired flash data and performs maintenance.
  void cleanupSession() => _session.cleanup();

  /// Gets all session data as a map (excluding internal metadata).
  Map<String, dynamic> getAllSessionData() => _session.getAllData();

  /// Checks if the session is about to expire within the given duration.
  bool isSessionExpiringSoon([Duration within = const Duration(minutes: 5)]) =>
      _session.isExpiringSoon(within);

  /// Web Authentication helpers
  /// Checks if user is authenticated via web auth service
  bool get isWebAuthenticated {
    try {
      final authService = WebAuthService.create();
      return authService.isAuthenticated(this);
    } catch (e) {
      return false;
    }
  }

  /// Gets current web user
  Future<Map<String, dynamic>?> getWebUser() async {
    try {
      final authService = WebAuthService.create();
      return await authService.getCurrentUser(this);
    } catch (e) {
      return null;
    }
  }

  /// Gets web authentication status
  Map<String, dynamic> get webAuthStatus {
    try {
      final authService = WebAuthService.create();
      return authService.getAuthStatus(this);
    } catch (e) {
      return {'is_authenticated': false};
    }
  }

  /// Gets data for web views (auth + flash messages)
  Map<String, dynamic> get webViewData {
    try {
      final authService = WebAuthService.create();
      return authService.getViewData(this);
    } catch (e) {
      return {'is_authenticated': false};
    }
  }

  /// Validates CSRF token
  bool validateCsrfToken(String token) {
    try {
      final authService = WebAuthService.create();
      return authService.validateCsrfToken(this, token);
    } catch (e) {
      return false;
    }
  }

  /// Generates new CSRF token
  String generateCsrfToken() {
    final authService = WebAuthService.create();
    return authService.generateCsrfToken(this);
  }

  /// Gets current CSRF token from session
  String? get sessionCsrfToken {
    try {
      final authService = WebAuthService.create();
      return authService.getCsrfToken(this);
    } catch (e) {
      return null;
    }
  }
}
