import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../context/response_context.dart';

/// Represents the HTTP response sent back to the client.
///
/// Provides helpers for setting status codes, sending JSON/text responses,
/// files, and redirects.
class Response {
  final HttpRequest _raw;
  bool _sent = false;

  Response(this._raw) {
    ResponseContext.run(this, () {});
  }

  HttpRequest get raw => _raw;

  /// Whether the response has already been sent.
  bool get sent => _sent;

  /// Sets the HTTP status code.
  Response status(int code) {
    _raw.response.statusCode = code;
    return this;
  }

  /// Adds a response header.
  Response header(String name, String value) {
    _raw.response.headers.add(name, value);
    return this;
  }

  /// Sends a plain text response.
  void send(String text) {
    if (_sent) return;
    _raw.response.headers.contentType = ContentType.text;
    _raw.response.write(text);
    _raw.response.close();
    _sent = true;
  }

  /// Sends a JSON response.
  void sendJson(Map<String, dynamic> data) {
    if (_sent) return;
    _raw.response.headers.contentType = ContentType.json;
    _raw.response.write(json.encode(data));
    _raw.response.close();
    _sent = true;
  }

  /// Redirects to another URL.
  Future<void> redirect(String url, {int status = 302}) async {
    if (_sent) return;
    _raw.response.statusCode = status;
    _raw.response.headers.set('Location', url);
    await _raw.response.close();
    _sent = true;
  }

  /// Streams any type of data to the client.
  /// Converts each item to a byte buffer using [toBytes] function (default: UTF8).
  Future<void> stream<T>(
    Stream<T> stream, {
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
    List<int> Function(T data)? toBytes,
  }) async {
    if (_sent) return;

    // Set headers
    _raw.response.headers.contentType = ContentType.parse(contentType);
    headers?.forEach((key, value) {
      _raw.response.headers.set(key, value);
    });

    // Use default converter for strings
    final converter = toBytes ??
        (T data) {
          if (data is List<int>) return data;
          if (data is String) return utf8.encode(data);
          throw ArgumentError(
            'Unsupported type: ${data.runtimeType}. Provide a custom toBytes converter.',
          );
        };

    // Pipe the stream to the response
    final byteStream = stream.map(converter);
    await _raw.response.addStream(byteStream);
    await _raw.response.close();
    _sent = true;
  }

  /// Sends a file response.
  Future<void> file(File file) async {
    if (_sent) return;
    _raw.response.headers.contentType = ContentType.parse(
        lookupMimeType(file.path) ?? 'application/octet-stream');
    await _raw.response.addStream(file.openRead());
    await _raw.response.close();
    _sent = true;
  }
}
