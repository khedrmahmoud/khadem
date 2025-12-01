import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

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
  bool _isParsing = false;
  bool _parsingFailed = false;

  // Default max body size: 10MB
  static const int defaultMaxBodySize = 10 * 1024 * 1024;
  final int maxBodySize;

  RequestBodyParser(this._raw, {this.maxBodySize = defaultMaxBodySize});

  /// Parses and returns the request body as a Map.
  /// Supports `application/json`, `application/x-www-form-urlencoded`, and `multipart/form-data`.
  Future<Map<String, dynamic>> parseBody() async {
    if (_parsedBody != null) return _parsedBody!;
    if (_parsingFailed) return {};
    if (_isParsing) {
      // Wait for ongoing parsing to complete
      while (_isParsing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _parsedBody ?? {};
    }

    _isParsing = true;
    try {
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
    } catch (e) {
      _parsingFailed = true;
      print('Warning: Failed to parse request body: $e');
      _parsedBody = {};
      _uploadedFiles = {};
      return _parsedBody!;
    } finally {
      _isParsing = false;
    }
  }

  /// Parses JSON body content.
  Future<Map<String, dynamic>> _parseJsonBody() async {
    try {
      final content = await _readBodyAsString();
      if (content.isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Invalid JSON format in request body');
    }
  }

  /// Parses form-encoded body content.
  Future<Map<String, dynamic>> _parseFormBody() async {
    try {
      final content = await _readBodyAsString();
      return Uri.splitQueryString(content);
    } catch (_) {
      throw const FormatException('Invalid form data in request body');
    }
  }

  /// Reads the body as a string with size limit enforcement.
  Future<String> _readBodyAsString() async {
    int bytesRead = 0;
    final completer = Completer<String>();
    final buffer = StringBuffer();

    _raw.cast<List<int>>().transform(utf8.decoder).listen(
      (chunk) {
        bytesRead += chunk.length;
        if (bytesRead > maxBodySize) {
          // We can't easily stop the stream from here without cancelling subscription
          // But we can throw an error which will trigger onError
          throw const FormatException('Request body too large');
        }
        buffer.write(chunk);
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Parses multipart/form-data body content using MimeMultipartTransformer.
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

      final transformer = MimeMultipartTransformer(boundary);
      final parts = _raw.cast<List<int>>().transform(transformer);

      await for (final part in parts) {
        final contentDisposition = part.headers['content-disposition'];
        if (contentDisposition == null) continue;

        final disposition = _parseContentDisposition(contentDisposition);
        final name = disposition['name'];
        final filename = disposition['filename'];

        if (name == null) continue;

        if (filename != null) {
          // This is a file
          // TODO: For large files, stream to disk instead of memory
          final content = await _readPartBytes(part);
          final contentType = part.headers['content-type'];
          files[name] = UploadedFile(filename, contentType, content, name);
        } else {
          // This is a form field
          final content = await utf8.decodeStream(part);
          fields[name] = _parseFieldValue(content);
        }
      }

      return {
        'fields': fields,
        'files': files,
      };
    } catch (e) {
      print('Warning: Failed to parse multipart data: $e');
      return {
        'fields': fields,
        'files': files,
      };
    }
  }

  Future<List<int>> _readPartBytes(Stream<List<int>> part) async {
    final bytes = <int>[];
    int totalBytes = 0;
    
    await for (final chunk in part) {
      totalBytes += chunk.length;
      if (totalBytes > maxBodySize) {
        throw const FormatException('File upload too large');
      }
      bytes.addAll(chunk);
    }
    return bytes;
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
