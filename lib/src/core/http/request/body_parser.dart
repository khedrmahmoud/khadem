import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import 'uploaded_file.dart';

/// Handles parsing of HTTP request bodies.
///
/// Supports JSON, form data, multipart data, and file uploads.
/// Implements caching and concurrent request handling for optimal performance.
class BodyParser {
  final HttpRequest _raw;
  Map<String, dynamic>? _parsedBody;
  Map<String, UploadedFile>? _uploadedFiles;
  Future<Map<String, dynamic>>? _parsingFuture;

  static const int defaultMaxBodySize = 10 * 1024 * 1024;
  final int maxBodySize;

  BodyParser(this._raw, {this.maxBodySize = defaultMaxBodySize});

  /// Parses and returns the request body as a Map.
  /// Caches results to avoid re-parsing.
  Future<Map<String, dynamic>> parse() {
    if (_parsedBody != null) return Future.value(_parsedBody!);
    if (_parsingFuture != null) return _parsingFuture!;

    _parsingFuture = _doParse();
    return _parsingFuture!;
  }

  Future<Map<String, dynamic>> _doParse() async {
    try {
      final contentType = _raw.headers.contentType?.mimeType;

      if (contentType == 'application/json') {
        _parsedBody = await _parseJson();
      } else if (contentType == 'application/x-www-form-urlencoded') {
        _parsedBody = await _parseForm();
      } else if (contentType?.startsWith('multipart/') == true) {
        final result = await _parseMultipart();
        _parsedBody = result['fields'] ?? {};
        _uploadedFiles = result['files'];
      } else {
        _parsedBody = {};
      }

      return _parsedBody!;
    } catch (e) {
      _parsedBody = {};
      _uploadedFiles = {};
      return _parsedBody!;
    }
  }

  Future<Map<String, dynamic>> _parseJson() async {
    try {
      final content = await _readBodyAsString();
      if (content.isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _parseForm() async {
    try {
      final content = await _readBodyAsString();
      return Uri.splitQueryString(content);
    } catch (_) {
      return {};
    }
  }

  Future<String> _readBodyAsString() async {
    int bytesRead = 0;
    final completer = Completer<String>();
    final buffer = StringBuffer();

    _raw.cast<List<int>>().transform(utf8.decoder).listen(
      (chunk) {
        bytesRead += chunk.length;
        if (bytesRead > maxBodySize) {
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

  Future<Map<String, dynamic>> _parseMultipart() async {
    final fields = <String, dynamic>{};
    final files = <String, UploadedFile>{};

    try {
      final boundary = _raw.headers.contentType?.parameters['boundary'];
      if (boundary == null) {
        return {'fields': fields, 'files': files};
      }

      final transformer = MimeMultipartTransformer(boundary);
      final parts = _raw.cast<List<int>>().transform(transformer);

      await for (final part in parts) {
        final contentDisposition = part.headers['content-disposition'];
        if (contentDisposition == null) continue;

        final disposition = _parseContentDisposition(contentDisposition);
        final name = disposition['name'];

        if (name == null) continue;

        if (disposition['filename'] != null) {
          final filename = disposition['filename']!;
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
          final content = await utf8.decodeStream(part);
          fields[name] = _parseFieldValue(content);
        }
      }

      return {'fields': fields, 'files': files};
    } catch (e) {
      return {'fields': fields, 'files': files};
    }
  }

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
        final cleanValue = value.startsWith('"') && value.endsWith('"')
            ? value.substring(1, value.length - 1)
            : value;
        result[key] = cleanValue;
      }
    }

    return result;
  }

  dynamic _parseFieldValue(String value) {
    final numValue = num.tryParse(value);
    if (numValue != null) return numValue;

    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  /// Gets parsed body.
  Map<String, dynamic>? get body => _parsedBody;

  /// Gets uploaded files.
  Map<String, UploadedFile>? get files => _uploadedFiles;

  /// Gets a specific input value.
  dynamic input(String key, [dynamic defaultValue]) {
    if (_parsedBody == null) {
      throw StateError('Body not parsed yet. Call parse() first.');
    }
    return _parsedBody![key] ?? defaultValue;
  }

  /// Checks if a key exists.
  bool has(String key) {
    if (_parsedBody == null) {
      throw StateError('Body not parsed yet. Call parse() first.');
    }
    return _parsedBody!.containsKey(key);
  }

  /// Gets a specific file.
  UploadedFile? file(String fieldName) => _uploadedFiles?[fieldName];

  /// Gets all files with a field name.
  List<UploadedFile> filesByName(String fieldName) {
    return _uploadedFiles?.values
            .where((file) => file.fieldName == fieldName)
            .toList() ??
        [];
  }

  /// Checks if a file was uploaded.
  bool hasFile(String fieldName) =>
      _uploadedFiles?.containsKey(fieldName) ?? false;

  /// Gets first file by field name.
  UploadedFile? firstFile(String fieldName) =>
      filesByName(fieldName).firstOrNull;

  /// Clears cached data.
  void clearCache() {
    _parsedBody = null;
    _uploadedFiles = null;
    _parsingFuture = null;
  }

  /// Cleans up temporary files.
  Future<void> cleanup() async {
    if (_uploadedFiles != null) {
      for (final file in _uploadedFiles!.values) {
        await file.deleteTempFile();
      }
    }
  }
}
