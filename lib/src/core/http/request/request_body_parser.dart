import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

/// Represents an uploaded file in a multipart request.
class UploadedFile {
  final String filename;
  final String? contentType;
  final String fieldName;
  final String? _tempFilePath;
  final List<int>? _memoryData;

  UploadedFile({
    required this.filename,
    required this.fieldName,
    this.contentType,
    String? tempFilePath,
    List<int>? data,
  })  : _tempFilePath = tempFilePath,
        _memoryData = data;

  /// Gets the file size in bytes.
  int get size {
    if (_memoryData != null) return _memoryData!.length;
    if (_tempFilePath != null) return File(_tempFilePath!).lengthSync();
    return 0;
  }

  /// Gets the file content as bytes.
  /// Warning: This reads the entire file into memory if it's stored on disk.
  List<int> get data {
    if (_memoryData != null) return _memoryData!;
    if (_tempFilePath != null) return File(_tempFilePath!).readAsBytesSync();
    return [];
  }

  /// Saves the file to the specified path.
  /// Efficiently moves the temp file if available, otherwise writes bytes.
  Future<String> saveTo(String path) async {
    if (_tempFilePath != null) {
      // Move the temp file to the new location
      final tempFile = File(_tempFilePath!);
      if (await tempFile.exists()) {
        await tempFile.rename(path);
        return path;
      }
    }

    final file = File(path);
    await file.writeAsBytes(data);
    return file.path;
  }

  /// Gets the file content as a string (if it's text).
  String asString() => utf8.decode(data);

  /// Gets the file extension.
  String get extension => filename.split('.').last.toLowerCase();

  /// Deletes the temporary file if it exists.
  Future<void> deleteTempFile() async {
    if (_tempFilePath != null) {
      final file = File(_tempFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

/// Handles parsing of HTTP request bodies.
/// Supports JSON, form data, multipart data, and file uploads.
class RequestBodyParser {
  final HttpRequest _raw;
  Map<String, dynamic>? _parsedBody;
  Map<String, UploadedFile>? _uploadedFiles;

  // Use a future to handle concurrent parsing requests
  Future<Map<String, dynamic>>? _parsingFuture;

  // Default max body size: 10MB
  static const int defaultMaxBodySize = 10 * 1024 * 1024;
  final int maxBodySize;

  RequestBodyParser(this._raw, {this.maxBodySize = defaultMaxBodySize});

  /// Parses and returns the request body as a Map.
  /// Supports `application/json`, `application/x-www-form-urlencoded`, and `multipart/form-data`.
  Future<Map<String, dynamic>> parseBody() {
    if (_parsedBody != null) return Future.value(_parsedBody!);

    // If parsing is already in progress, return the existing future
    if (_parsingFuture != null) return _parsingFuture!;

    _parsingFuture = _doParseBody();
    return _parsingFuture!;
  }

  Future<Map<String, dynamic>> _doParseBody() async {
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
      print('Warning: Failed to parse request body: $e');
      _parsedBody = {};
      _uploadedFiles = {};
      return _parsedBody!;
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
          // Stream file to temporary location
          final tempDir = Directory.systemTemp.createTempSync('khadem_upload_');
          final tempFile = File('${tempDir.path}/$filename');
          final sink = tempFile.openWrite();

          int totalBytes = 0;
          await for (final chunk in part) {
            totalBytes += chunk.length;
            if (totalBytes > maxBodySize) {
              await sink.close();
              await tempFile.delete();
              await tempDir.delete();
              throw const FormatException('File upload too large');
            }
            sink.add(chunk);
          }
          await sink.close();

          final contentType = part.headers['content-type'];
          files[name] = UploadedFile(
            filename: filename,
            fieldName: name,
            contentType: contentType,
            tempFilePath: tempFile.path,
          );
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
    _parsingFuture = null;
  }

  /// Cleans up any temporary files created during parsing.
  Future<void> cleanup() async {
    if (_uploadedFiles != null) {
      for (final file in _uploadedFiles!.values) {
        await file.deleteTempFile();
      }
    }
  }
}
