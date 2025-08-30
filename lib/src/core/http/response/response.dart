import 'dart:io';

import '../context/response_context.dart';
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
class Response {
  final HttpRequest _raw;
  bool _sent = false;

  late final ResponseHeaders _headers;
  late final ResponseBody _body;
  late final ResponseStatus _status;
  late final ResponseRenderer _renderer;

  Response(this._raw) {
    ResponseContext.run(this, () {
      _headers = ResponseHeaders(_raw.response);
      _body = ResponseBody(_raw.response, _headers);
      _status = ResponseStatus(_raw.response);
      _renderer = ResponseRenderer(_body, _headers);
    });
  }

  /// Raw HttpRequest from Dart SDK
  HttpRequest get raw => _raw;

  /// Whether the response has already been sent.
  bool get sent => _sent;

  /// Access to header management functionality
  ResponseHeaders get headers => _headers;

  /// Access to status code management functionality
  ResponseStatus get statusManager => _status;

  /// Access to body content functionality
  ResponseBody get body => _body;

  /// Access to view rendering functionality
  ResponseRenderer get renderer => _renderer;

  /// Sets the HTTP status code (legacy method for backward compatibility).
  Response status(int code) {
    _status.setStatus(code);
    return this;
  }

  /// Sets the HTTP status code (convenience method).
  Response statusCode(int code) {
    _status.setStatus(code);
    return this;
  }

  /// Adds a response header (convenience method).
  Response header(String name, String value) {
    _headers.setHeader(name, value);
    return this;
  }

  /// Sends a plain text response (convenience method).
  void send(String text) {
    _body.sendText(text);
    _sent = true;
  }

  /// Sends a JSON response (convenience method).
  void sendJson(Map<String, dynamic> data) {
    _body.sendJson(data);
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
    await _body.stream(stream,
        contentType: contentType, headers: headers, toBytes: toBytes,);
    _sent = true;
  }

  /// Sends a file response (convenience method).
  Future<void> file(File file) async {
    await _body.sendFile(file);
    _sent = true;
  }

  /// Renders a view template (convenience method).
  Future<void> view(String viewName,
      {Map<String, dynamic> data = const {},}) async {
    await _renderer.renderView(viewName, data: data);
    _sent = true;
  }

  /// Sends an HTML response (convenience method).
  void html(String html) {
    _body.sendHtml(html);
    _sent = true;
  }

  /// Sends binary data (convenience method).
  void bytes(List<int> bytes, {String contentType = 'application/octet-stream'}) {
    _body.sendBytes(bytes, contentType: contentType);
    _sent = true;
  }

  /// Sends a pretty-printed JSON response (convenience method).
  void jsonPretty(dynamic data, {int indent = 2}) {
    _body.sendJsonPretty(data, indent: indent);
    _sent = true;
  }

  /// Sends an empty response (convenience method).
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
}
