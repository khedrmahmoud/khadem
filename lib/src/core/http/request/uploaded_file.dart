import 'dart:convert';
import 'dart:io';

/// Represents an uploaded file in a multipart request.
///
/// Handles file metadata, storage location, and efficient
/// file operations (saving, reading, deleting).
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

  /// Gets the temporary file path if available.
  String? get tempPath => _tempFilePath;

  /// Checks if file is stored in memory.
  bool get isMemoryBased => _memoryData != null;

  /// Checks if file is stored on disk.
  bool get isDiskBased => _tempFilePath != null;

  /// Saves the file to the specified path.
  /// Efficiently moves the temp file if available, otherwise writes bytes.
  Future<String> saveTo(String path) async {
    if (_tempFilePath != null) {
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
  String asString([Encoding encoding = utf8]) => encoding.decode(data);

  /// Gets the file extension (without dot).
  String get extension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Gets the filename without extension.
  String get nameWithoutExtension {
    final parts = filename.split('.');
    return parts.length > 1
        ? parts.sublist(0, parts.length - 1).join('.')
        : filename;
  }

  /// Gets the MIME type if available.
  String? get mimeType => contentType;

  /// Checks if the file has a specific MIME type.
  bool isMimeType(String type) {
    if (contentType == null) return false;
    return contentType!.toLowerCase().contains(type.toLowerCase());
  }

  /// Deletes the temporary file if it exists.
  Future<void> deleteTempFile() async {
    if (_tempFilePath != null) {
      final file = File(_tempFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Copies the file to a new location.
  Future<String> copyTo(String path) async {
    if (_tempFilePath != null) {
      final tempFile = File(_tempFilePath!);
      if (await tempFile.exists()) {
        await tempFile.copy(path);
        return path;
      }
    }

    final file = File(path);
    await file.writeAsBytes(data);
    return file.path;
  }

  /// Gets file details as a map.
  Map<String, dynamic> toMap() => {
        'filename': filename,
        'field_name': fieldName,
        'content_type': contentType,
        'size': size,
        'extension': extension,
        'is_memory_based': isMemoryBased,
        'is_disk_based': isDiskBased,
      };
}
