import 'dart:io';

import '../../../contracts/http/response_contract.dart';
import '../cookie.dart';
import '../request/request.dart';
import 'response_body.dart';
import 'response_headers.dart';
import 'response_renderer.dart';
import 'response_status.dart';


/// Represents the HTTP response sent back to the client.
///
/// This class orchestrates the response process using specialized components
/// for better maintainability and separation of concerns.
///
/// Key features:
/// - Modular design with separate components for headers, body, status, and rendering
/// - Convenient shortcuts for common operations
/// - Proper resource management and response state tracking
class Response implements ResponseContract {
  final HttpRequest _raw;
  bool _sent = false;
  Request? _request;

  late final ResponseHeaders _headers;
  late final ResponseBody _body;
  late final ResponseStatus _status;
  late final ResponseRenderer _renderer;
  late final Cookies _cookies;

  Response(this._raw) {
    _headers = ResponseHeaders(_raw.response);
    _body = ResponseBody(_raw.response, _headers);
    _status = ResponseStatus(_raw.response);
    _renderer = ResponseRenderer(_body, _headers);
    _cookies = Cookies.response(_raw.response);
  }

  /// Raw HttpRequest from Dart SDK
  HttpRequest get raw => _raw;

  /// The request object associated with this response.
  Request? get request => _request;

  /// Sets the request object associated with this response.
  void setRequest(Request request) {
    _request = request;
    _renderer.setRequest(request);
  }

  /// Whether the response has already been sent.
  @override
  bool get sent => _sent;

  /// Access to header management functionality
  ResponseHeaders get headers => _headers;

  /// Access to status code management functionality
  ResponseStatus get statusManager => _status;

  /// Access to response status functionality
  @override
  int get statusCode => _status.statusCode;

  /// Access to body content functionality
  ResponseBody get body => _body;

  /// Access to view rendering functionality
  ResponseRenderer get renderer => _renderer;

  /// Cookie management
  Cookies get cookieHandler => _cookies;

  /// Sets the HTTP status code (legacy method for backward compatibility).
  @override
  Response status(int code) {
    _status.setStatus(code);
    return this;
  }

  /// Sets the HTTP status code (convenience method).
  @override
  Response setStatusCode(int code) {
    _status.setStatus(code);
    return this;
  }

  /// Adds a response header (convenience method).
  @override
  Response header(String name, String value) {
    _headers.setHeader(name, value);
    return this;
  }

  /// Sets multiple headers (convenience method).
  @override
  Response withHeaders(Map<String, String> headers) {
    headers.forEach((key, value) {
      _headers.setHeader(key, value);
    });
    return this;
  }

  /// Sets a cookie (convenience method).
  Response cookie(
    String name,
    String value, {
    String? domain,
    String? path = '/',
    DateTime? expires,
    Duration? maxAge,
    bool httpOnly = false,
    bool secure = false,
    String? sameSite,
  }) {
    _cookies.set(
      name,
      value,
      domain: domain,
      path: path,
      expires: expires,
      maxAge: maxAge,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: sameSite,
    );
    return this;
  }

  /// Sends a plain text response (convenience method).
  @override
  void send(String text) {
    _body.sendText(text);
    _sent = true;
  }

  /// Sends a JSON response (convenience method).
  @override
  void sendJson(dynamic data) {
    _body.sendJson(data);
    _sent = true;
  }

  /// Alias for sendJson.
  @override
  void json(dynamic data) => sendJson(data);

  /// Sends an HTML response (convenience method).
  void sendHtml(String html) {
    _body.sendHtml(html);
    _sent = true;
  }

  /// Alias for sendHtml.
  void html(String html) => sendHtml(html);

  /// Sends a file response.
  Future<void> file(File file, {String? contentType}) async {
    await _body.sendFile(
      file,
      contentType: contentType,
      rangeHeader: _raw.headers.value(HttpHeaders.rangeHeader),
    );
    _sent = true;
  }

  /// Redirects back to the previous page.
  Future<void> back({String fallback = '/'}) async {
    final referer = _raw.headers.value(HttpHeaders.refererHeader);
    await redirect(referer ?? fallback);
  }

  /// Sends a Problem Details response (RFC 7807).
  @override
  void problem({
    required String title,
    required int status,
    String? detail,
    String? type,
    String? instance,
    Map<String, dynamic>? extensions,
  }) {
    _status.setStatus(status);
    _headers.setContentTypeString('application/problem+json');

    final problem = {
      'type': type ?? 'about:blank',
      'title': title,
      'status': status,
      if (detail != null) 'detail': detail,
      if (instance != null) 'instance': instance,
      if (extensions != null) ...extensions,
    };

    _body.sendJson(problem, contentType: 'application/problem+json');
    _sent = true;
  }

  /// Content negotiation helper.
  ///
  /// Example:
  /// ```dart
  /// res.format({
  ///   'json': () => res.json(data),
  ///   'html': () => res.view('index', data),
  /// });
  /// ```
  Future<void> format(Map<String, Function> formats) async {
    final accept = _raw.headers.value(HttpHeaders.acceptHeader) ?? '';

    if (accept.contains('application/json') && formats.containsKey('json')) {
      await formats['json']!();
    } else if (accept.contains('text/html') && formats.containsKey('html')) {
      await formats['html']!();
    } else {
      // Default to first format or json
      if (formats.isNotEmpty) {
        await formats.values.first();
      } else {
        status(406).send('Not Acceptable');
      }
    }
  }

  /// Sends a file download response.
  Future<void> download(
    File file, {
    String? name,
    bool inline = false,
    String? contentType,
  }) async {
    await _body.download(
      file,
      name: name,
      inline: inline,
      contentType: contentType,
    );
    _sent = true;
  }

  /// Redirects to another URL (convenience method).
  Future<void> redirect(String url, {int status = 302}) async {
    _status.setStatus(status);
    _headers.setLocation(url);
    _body.sendEmpty();
    _sent = true;
  }

  /// Streams any type of data to the client (convenience method).
  Future<void> stream<T>(
    Stream<T> stream, {
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
    List<int> Function(T)? toBytes,
  }) async {
    await _body.stream(
      stream,
      contentType: contentType,
      headers: headers,
      toBytes: toBytes,
    );
    _sent = true;
  }

  /// Renders a view template (convenience method).
  Future<void> view(
    String viewName, {
    Map<String, dynamic> data = const {},
  }) async {
    await _renderer.renderView(viewName, data: data);
    _sent = true;
  }

  /// Sends binary data (convenience method).
  void bytes(
    List<int> bytes, {
    String contentType = 'application/octet-stream',
  }) {
    _body.sendBytes(bytes, contentType: contentType);
    _sent = true;
  }

  /// Sends a pretty-printed JSON response (convenience method).
  void jsonPretty(dynamic data, {int indent = 2}) {
    _body.sendJsonPretty(data, indent: indent);
    _sent = true;
  }

  /// Sends an empty response (convenience method).
  @override
  void empty() {
    _body.sendEmpty();
    _sent = true;
  }

  /// Sets common success status codes
  Response ok() {
    _status.ok();
    return this;
  }

  Response created() {
    _status.created();
    return this;
  }

  Response accepted() {
    _status.accepted();
    return this;
  }

  Response noContent() {
    _status.noContent();
    return this;
  }

  /// Sets common error status codes
  Response badRequest() {
    _status.badRequest();
    return this;
  }

  Response unauthorized() {
    _status.unauthorized();
    return this;
  }

  Response forbidden() {
    _status.forbidden();
    return this;
  }

  Response notFound() {
    _status.notFound();
    return this;
  }

  Response internalServerError() {
    _status.internalServerError();
    return this;
  }

  /// Sets CORS headers (convenience method)
  @override
  Response cors({
    String? allowOrigin,
    String? allowMethods,
    String? allowHeaders,
    String? exposeHeaders,
    bool allowCredentials = false,
    int? maxAge,
  }) {
    _headers.setCorsHeaders(
      allowOrigin: allowOrigin,
      allowMethods: allowMethods,
      allowHeaders: allowHeaders,
      exposeHeaders: exposeHeaders,
      allowCredentials: allowCredentials,
      maxAge: maxAge,
    );
    return this;
  }

  /// Sets security headers (convenience method)
  @override
  Response security({
    bool enableHsts = false,
    bool enableCsp = false,
    bool enableXFrameOptions = true,
    bool enableXContentTypeOptions = true,
    String? cspPolicy,
  }) {
    _headers.setSecurityHeaders(
      enableHsts: enableHsts,
      enableCsp: enableCsp,
      enableXFrameOptions: enableXFrameOptions,
      enableXContentTypeOptions: enableXContentTypeOptions,
      cspPolicy: cspPolicy,
    );
    return this;
  }

  /// Sets cache control headers (convenience method)
  Response cache(String value) {
    _headers.setCacheControl(value);
    return this;
  }

  /// Sets no-cache headers (convenience method)
  Response noCache() {
    _headers.setCacheControl('no-cache, no-store, must-revalidate');
    _headers.setHeader('Pragma', 'no-cache');
    _headers.setExpires(DateTime.now());
    return this;
  }

  /// Enables Gzip compression for the response.
  Response gzip() {
    _body.enableCompression();
    return this;
  }
}
