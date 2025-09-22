import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Represents an uploaded file in a multipart request.
class UploadedFile {
  final String filename;
  final String? contentType;
  final List<int> data;
  final String fieldName;

  UploadedFile(this.filename, this.contentType, this.data, this.fieldName);

  /// Gets the file size in bytes.
  int get size => data.length;

  /// Saves the file to the specified path.
  Future<String> saveTo(String path) async {
    final file = File(path);
    final savedFile = await file.writeAsBytes(data);
    return savedFile.path;
  }

  /// Gets the file content as a string (if it's text).
  String asString() => utf8.decode(data);

  /// Gets the file extension.
  String get extension => filename.split('.').last.toLowerCase();
}

/// Handles parsing of HTTP request bodies.
/// Supports JSON, form data, multipart data, and file uploads.
class RequestBodyParser {
  final HttpRequest _raw;
  Map<String, dynamic>? _parsedBody;
  Map<String, UploadedFile>? _uploadedFiles;

  RequestBodyParser(this._raw);

  /// Parses and returns the request body as a Map.
  /// Supports `application/json`, `application/x-www-form-urlencoded`, and `multipart/form-data`.
  Future<Map<String, dynamic>> parseBody() async {
    if (_parsedBody != null) return _parsedBody!;

    final contentType = _raw.headers.contentType?.mimeType;

    if (contentType == 'application/json') {
      _parsedBody = await _parseJsonBody();
    } else if (contentType == 'application/x-www-form-urlencoded') {
      _parsedBody = await _parseFormBody();
    } else if (contentType?.startsWith('multipart/') == true) {
      final result = await _parseMultipartBody();
      _parsedBody = result['fields'] ?? {};
      _uploadedFiles = result['files'];
    } else {
      _parsedBody = {};
    }

    return _parsedBody!;
  }

  /// Parses JSON body content.
  Future<Map<String, dynamic>> _parseJsonBody() async {
    try {
      final bodyString = await utf8.decoder.bind(_raw).join();
      return jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Invalid JSON format in request body');
    }
  }

  /// Parses form-encoded body content.
  Future<Map<String, dynamic>> _parseFormBody() async {
    try {
      final bodyString = await utf8.decoder.bind(_raw).join();
      return Uri.splitQueryString(bodyString);
    } catch (_) {
      throw const FormatException('Invalid form data in request body');
    }
  }

  /// Parses multipart/form-data body content.
  Future<Map<String, dynamic>> _parseMultipartBody() async {
    final fields = <String, dynamic>{};
    final files = <String, UploadedFile>{};

    try {
      final boundary = _raw.headers.contentType?.parameters['boundary'];
      if (boundary == null) {
        throw const FormatException(
          'Missing boundary in multipart content type',
        );
      }

      // Read all bytes from the request
      final bytes = <int>[];
      await for (final chunk in _raw) {
        bytes.addAll(chunk);
      }

      // Parse multipart data
      final boundaryBytes = '--$boundary'.codeUnits;
      final endBoundaryBytes = '--$boundary--'.codeUnits;
      final crlf = '\r\n'.codeUnits;

      int position = 0;

      // Skip initial boundary
      if (!_matchBytes(bytes, position, boundaryBytes)) {
        throw const FormatException('Invalid multipart format');
      }
      position += boundaryBytes.length;

      while (position < bytes.length) {
        // Skip CRLF after boundary
        if (_matchBytes(bytes, position, crlf)) {
          position += crlf.length;
        }

        // Check for end boundary
        if (_matchBytes(bytes, position, endBoundaryBytes)) {
          break;
        }

        // Parse headers
        final headers = <String, String>{};
        while (position < bytes.length) {
          final lineEnd = _findBytes(bytes, position, crlf);
          if (lineEnd == -1) break;

          final line = utf8.decode(bytes.sublist(position, lineEnd));
          position = lineEnd + crlf.length;

          if (line.isEmpty) break; // Empty line indicates end of headers

          final colonIndex = line.indexOf(':');
          if (colonIndex != -1) {
            final headerName =
                line.substring(0, colonIndex).trim().toLowerCase();
            final headerValue = line.substring(colonIndex + 1).trim();
            headers[headerName] = headerValue;
          }
        }

        // Find content end (next boundary)
        final contentStart = position;
        final nextBoundary = _findBytes(bytes, position, boundaryBytes);
        if (nextBoundary == -1) break;

        final contentEnd = nextBoundary - crlf.length; // Remove trailing CRLF
        final content = bytes.sublist(contentStart, contentEnd);

        // Process the part based on Content-Disposition
        final contentDisposition = headers['content-disposition'];
        if (contentDisposition != null) {
          final disposition = _parseContentDisposition(contentDisposition);
          final fieldName = disposition['name'];

          if (fieldName != null) {
            final filename = disposition['filename'];

            if (filename != null) {
              // This is a file
              final contentType = headers['content-type'];
              files[fieldName] =
                  UploadedFile(filename, contentType, content, fieldName);
            } else {
              // This is a form field
              final value = utf8.decode(content);
              fields[fieldName] = _parseFieldValue(value);
            }
          }
        }

        position = nextBoundary + boundaryBytes.length;
      }

      return {
        'fields': fields,
        'files': files,
      };
    } catch (e) {
      throw FormatException('Invalid multipart data: $e');
    }
  }

  /// Parses Content-Disposition header
  Map<String, String?> _parseContentDisposition(String header) {
    final result = <String, String?>{};
    final parts = header.split(';');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('form-data')) continue;

      final eqIndex = trimmed.indexOf('=');
      if (eqIndex != -1) {
        final key = trimmed.substring(0, eqIndex).trim();
        final value = trimmed.substring(eqIndex + 1).trim();
        // Remove quotes if present
        final cleanValue = value.startsWith('"') && value.endsWith('"')
            ? value.substring(1, value.length - 1)
            : value;
        result[key] = cleanValue;
      }
    }

    return result;
  }

  /// Parses field value and converts to appropriate type
  dynamic _parseFieldValue(String value) {
    // Try to parse as number
    final numValue = num.tryParse(value);
    if (numValue != null) {
      return numValue;
    }

    // Try to parse as boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Try to parse as JSON array/object
    try {
      return jsonDecode(value);
    } catch (_) {
      // Not JSON, return as string
    }

    return value;
  }

  /// Checks if bytes match at given position
  bool _matchBytes(List<int> bytes, int position, List<int> pattern) {
    if (position + pattern.length > bytes.length) return false;

    for (int i = 0; i < pattern.length; i++) {
      if (bytes[position + i] != pattern[i]) return false;
    }

    return true;
  }

  /// Finds pattern in bytes starting from position
  int _findBytes(List<int> bytes, int start, List<int> pattern) {
    for (int i = start; i <= bytes.length - pattern.length; i++) {
      if (_matchBytes(bytes, i, pattern)) {
        return i;
      }
    }
    return -1;
  }

  /// Gets uploaded files from the request.
  Map<String, UploadedFile>? get files => _uploadedFiles;

  /// Gets a specific uploaded file by field name.
  UploadedFile? file(String fieldName) => _uploadedFiles?[fieldName];

  /// Gets all files with a specific field name (for multiple file uploads).
  List<UploadedFile> filesByName(String fieldName) {
    return _uploadedFiles?.values
            .where((file) => file.fieldName == fieldName)
            .toList() ??
        [];
  }

  /// Checks if a file was uploaded with the given field name.
  bool hasFile(String fieldName) =>
      _uploadedFiles?.containsKey(fieldName) ?? false;

  /// Gets the first file from multiple files with the same name.
  UploadedFile? firstFile(String fieldName) =>
      filesByName(fieldName).firstOrNull;

  /// Gets a specific input value from the parsed body.
  /// Throws if body not parsed yet.
  /// If key not found, returns [defaultValue] or null.
  dynamic input(String key, [dynamic defaultValue]) {
    if (_parsedBody == null) {
      throw StateError('Request body not parsed yet. Call parseBody() first.');
    }
    return _parsedBody![key] ?? defaultValue;
  }

  /// Checks if a specific key exists in the parsed body.
  /// Throws if body not parsed yet.
  bool has(String key) {
    if (_parsedBody == null) {
      throw StateError('Request body not parsed yet. Call parseBody() first.');
    }
    return _parsedBody!.containsKey(key);
  }

  /// Clears the cached parsed body and files.
  void clearCache() {
    _parsedBody = null;
    _uploadedFiles = null;
  }
}
