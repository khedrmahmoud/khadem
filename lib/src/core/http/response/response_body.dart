import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import 'response_headers.dart';

/// Handles HTTP response body content with support for various formats.
///
/// This class provides methods for sending different types of content including
/// text, JSON, files, streams, and binary data.
class ResponseBody {
  final HttpResponse _response;
  final ResponseHeaders _headers;
  bool _sent = false;

  ResponseBody(this._response, this._headers);

  /// Whether the response body has already been sent.
  bool get sent => _sent;

  /// Sends a plain text response.
  void sendText(String text) {
    if (_sent) return;

    _headers.setContentType(ContentType.text);
    _response.write(text);
    _closeResponse();
  }

  /// Sends an HTML response.
  void sendHtml(String html) {
    if (_sent) return;

    _headers.setContentType(ContentType.html);
    _response.write(html);
    _closeResponse();
  }

  /// Sends a JSON response.
  void sendJson(dynamic data) {
    if (_sent) return;

    _headers.setContentType(ContentType.json);
    final jsonString = data is String ? data : json.encode(data);
    _response.write(jsonString);
    _closeResponse();
  }

  /// Sends a JSON response with pretty printing.
  void sendJsonPretty(dynamic data, {int indent = 2}) {
    if (_sent) return;

    _headers.setContentType(ContentType.json);
    final encoder = JsonEncoder.withIndent(' ' * indent);
    _response.write(encoder.convert(data));
    _closeResponse();
  }

  /// Sends binary data.
  void sendBytes(
    List<int> bytes, {
    String contentType = 'application/octet-stream',
  }) {
    if (_sent) return;

    _headers.setContentTypeString(contentType);
    _response.add(bytes);
    _closeResponse();
  }

  /// Sends a file response with proper MIME type detection.
  Future<void> sendFile(File file, {String? contentType}) async {
    if (_sent) return;

    final mimeType =
        contentType ?? lookupMimeType(file.path) ?? 'application/octet-stream';
    _headers.setContentTypeString(mimeType);

    // Set content length if file size is available
    try {
      final length = await file.length();
      _headers.setContentLength(length);
    } catch (_) {
      // Ignore if we can't get file length
    }

    await _response.addStream(file.openRead());
    _closeResponse();
  }

  /// Streams data to the client with optional transformation.
  Future<void> stream<T>(
    Stream<T> stream, {
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
    List<int> Function(T data)? toBytes,
  }) async {
    if (_sent) return;

    // Set content type
    _headers.setContentTypeString(contentType);

    // Set additional headers
    headers?.forEach((key, value) {
      _headers.setHeader(key, value);
    });

    // Use default converter for common types
    final converter = toBytes ??
        (T data) {
          if (data is List<int>) return data;
          if (data is String) return utf8.encode(data);
          throw ArgumentError(
            'Unsupported type: ${data.runtimeType}. Provide a custom toBytes converter.',
          );
        };

    // Transform and stream the data
    final byteStream = stream.map(converter);
    await _response.addStream(byteStream);
    _closeResponse();
  }

  /// Sends a chunked response with manual control over chunks.
  void sendChunked(String data) {
    if (_sent) return;

    _response.write(data);
    // Don't close - allow more chunks
  }

  /// Sends an empty response (useful for 204 No Content).
  void sendEmpty() {
    if (_sent) return;

    _closeResponse();
  }

  /// Sends a custom response with full control.
  void sendCustom({
    required String content,
    required ContentType contentType,
    Map<String, String>? headers,
  }) {
    if (_sent) return;

    _headers.setContentType(contentType);
    headers?.forEach((key, value) {
      _headers.setHeader(key, value);
    });

    _response.write(content);
    _closeResponse();
  }

  /// Helper method to close the response and mark as sent.
  void _closeResponse() {
    _response.close();
    _sent = true;
  }
}
