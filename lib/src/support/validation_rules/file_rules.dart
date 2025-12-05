import '../../contracts/validation/rule.dart';
import '../../core/http/request/uploaded_file.dart';

class FileRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'file_validation';
    }

    // Check if it's an UploadedFile or List of UploadedFile
    if (value is! UploadedFile && !(value is List<UploadedFile>)) {
      return 'file_validation';
    }

    // If it's a list, check that all items are UploadedFile
    if (value is List<UploadedFile>) {
      if (value.isEmpty) {
        return 'file_required_validation';
      }
      // All items are guaranteed to be UploadedFile due to type checking
    }

    return null;
  }
}

class ImageRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'image_validation';
    }

    // Check if it's a file first
    final fileRule = FileRule();
    if (fileRule.validate(field, value, arg, data: data) != null) {
      return 'image_validation';
    }

    // Define allowed image MIME types and extensions
    final allowedMimeTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/webp',
      'image/svg+xml',
    ];

    final allowedExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'svg',
    ];

    // Check single file
    if (value is UploadedFile) {
      return _validateImageFile(
        field,
        value,
        allowedMimeTypes,
        allowedExtensions,
      );
    }

    // Check multiple files
    if (value is List<UploadedFile>) {
      for (final file in value) {
        final error = _validateImageFile(
          field,
          file,
          allowedMimeTypes,
          allowedExtensions,
        );
        if (error != null) return error;
      }
    }

    return null;
  }

  String? _validateImageFile(
    String field,
    UploadedFile file,
    List<String> allowedMimeTypes,
    List<String> allowedExtensions,
  ) {
    // Check MIME type if available
    if (file.contentType != null &&
        !allowedMimeTypes.contains(file.contentType)) {
      return 'image_validation';
    }

    // Check file extension
    if (!allowedExtensions.contains(file.extension)) {
      return 'image_validation';
    }

    return null;
  }
}

class MimesRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'invalid_mime_type_validation';
    }

    // Check if it's a file first
    final fileRule = FileRule();
    if (fileRule.validate(field, value, arg, data: data) != null) {
      return 'file_validation';
    }

    final allowedTypes =
        arg.split(',').map((e) => e.trim().toLowerCase()).toList();

    // Check single file
    if (value is UploadedFile) {
      return _validateMimeType(field, value, allowedTypes);
    }

    // Check multiple files
    if (value is List<UploadedFile>) {
      for (final file in value) {
        final error = _validateMimeType(field, file, allowedTypes);
        if (error != null) return error;
      }
    }

    return null;
  }

  String? _validateMimeType(
    String field,
    UploadedFile file,
    List<String> allowedTypes,
  ) {
    // Check MIME type if available
    if (file.contentType != null) {
      final mimeType = file.contentType!.toLowerCase();
      if (allowedTypes.contains(mimeType)) {
        return null;
      }
    }

    // Check file extension as fallback
    if (allowedTypes.contains(file.extension)) {
      return null;
    }

    // Check against common MIME type mappings
    final mimeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'json': 'application/json',
      'xml': 'application/xml',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
    };

    final mappedMime = mimeMap[file.extension];
    if (mappedMime != null && allowedTypes.contains(mappedMime)) {
      return null;
    }

    return 'invalid_file_type_validation';
  }
}

class MaxFileSizeRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'invalid_max_size_validation';
    }

    // Check if it's a file first
    final fileRule = FileRule();
    if (fileRule.validate(field, value, arg, data: data) != null) {
      return 'file_validation';
    }

    final maxSize = int.tryParse(arg);
    if (maxSize == null) {
      return 'invalid_max_size_validation';
    }

    // Check single file
    if (value is UploadedFile) {
      if (value.size > maxSize) {
        return 'file_too_large_validation';
      }
    }

    // Check multiple files
    if (value is List<UploadedFile>) {
      for (final file in value) {
        if (file.size > maxSize) {
          return 'files_too_large_validation';
        }
      }
    }

    return null;
  }
}

class MinFileSizeRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'invalid_min_size_validation';
    }

    final fileRule = FileRule();
    if (fileRule.validate(field, value, arg, data: data) != null) {
      return 'file_validation';
    }

    final minSize = int.tryParse(arg);
    if (minSize == null) {
      return 'invalid_min_size_validation';
    }

    if (value is UploadedFile) {
      if (value.size < minSize) {
        return 'file_too_small_validation';
      }
    }

    if (value is List<UploadedFile>) {
      for (final file in value) {
        if (file.size < minSize) {
          return 'files_too_small_validation';
        }
      }
    }

    return null;
  }
}
