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
  bool _compression = false;

  ResponseBody(this._response, this._headers);

  /// Whether the response body has already been sent.
  bool get sent => _sent;

  /// Enables response compression (Gzip).
  void enableCompression() {
    _compression = true;
    _headers.setHeader('Content-Encoding', 'gzip');
  }

  /// Sends a plain text response.
  void sendText(String text) {
    if (_sent) return;

    _headers.setContentType(ContentType.text);
    if (_compression) {
      _response.add(gzip.encode(utf8.encode(text)));
    } else {
      _response.write(text);
    }
    _closeResponse();
  }

  /// Sends an HTML response.
  void sendHtml(String html) {
    if (_sent) return;

    _headers.setContentType(ContentType.html);
    if (_compression) {
      _response.add(gzip.encode(utf8.encode(html)));
    } else {
      _response.write(html);
    }
    _closeResponse();
  }

  /// Sends a JSON response.
  void sendJson(dynamic data, {String? contentType}) {
    if (_sent) return;

    _headers.setContentTypeString(contentType ?? 'application/json');
    final jsonString = data is String ? data : json.encode(data);
    if (_compression) {
      _response.add(gzip.encode(utf8.encode(jsonString)));
    } else {
      _response.write(jsonString);
    }
    _closeResponse();
  }

  /// Sends a JSON response with pretty printing.
  void sendJsonPretty(dynamic data, {int indent = 2}) {
    if (_sent) return;

    _headers.setContentType(ContentType.json);
    final encoder = JsonEncoder.withIndent(' ' * indent);
    final jsonString = encoder.convert(data);
    if (_compression) {
      _response.add(gzip.encode(utf8.encode(jsonString)));
    } else {
      _response.write(jsonString);
    }
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

  /// Sends a file response with proper MIME type detection and Range support.
  Future<void> sendFile(
    File file, {
    String? contentType,
    String? rangeHeader,
  }) async {
    if (_sent) return;

    final mimeType =
        contentType ?? lookupMimeType(file.path) ?? 'application/octet-stream';
    _headers.setContentTypeString(mimeType);

    final length = await file.length();

    // Handle Range Request
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final ranges = rangeHeader.substring(6).split('-');
      if (ranges.length == 2) {
        final start = int.tryParse(ranges[0]) ?? 0;
        final end = int.tryParse(ranges[1]) ?? length - 1;

        if (start >= 0 && end < length && start <= end) {
          final contentLength = end - start + 1;

          _response.statusCode = HttpStatus.partialContent;
          _headers.setHeader('Content-Range', 'bytes $start-$end/$length');
          _headers.setContentLength(contentLength);
          _headers.setHeader('Accept-Ranges', 'bytes');

          await _response.addStream(file.openRead(start, end + 1));
          _closeResponse();
          return;
        }
      }
    }

    // Standard file response
    _headers.setContentLength(length);
    _headers.setHeader('Accept-Ranges', 'bytes');
    await _response.addStream(file.openRead());
    _closeResponse();
  }

  /// Sends a file download response.
  Future<void> download(
    File file, {
    String? name,
    bool inline = false,
    String? contentType,
  }) async {
    if (_sent) return;

    final filename = name ?? file.uri.pathSegments.last;
    final disposition = inline ? 'inline' : 'attachment';

    _headers.setHeader(
      'Content-Disposition',
      '$disposition; filename="$filename"',
    );

    await sendFile(file, contentType: contentType);
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
