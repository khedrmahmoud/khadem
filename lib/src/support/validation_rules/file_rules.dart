import '../../contracts/validation/rule.dart';

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

    // For now, we'll do basic file validation
    // In a real implementation, this would check if the value is a valid file
    if (value is! String && !(value is List) && value is! Map) {
      return 'file_validation';
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

    // In a real implementation, this would check image file extensions
    // For now, we'll accept common image extensions
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];

    if (value is String) {
      final extension = value.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        return 'image_validation';
      }
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
      return 'mimes_validation';
    }

    // Check if it's a file first
    final fileRule = FileRule();
    if (fileRule.validate(field, value, arg, data: data) != null) {
      return 'mimes_validation';
    }

    final allowedTypes = arg.split(',').map((e) => e.trim().toLowerCase()).toList();

    if (value is String) {
      final extension = value.split('.').last.toLowerCase();
      // Check if the allowed types contain the extension directly
      if (allowedTypes.contains(extension)) {
        return null;
      }

      // Also check against mime type mapping
      final mimeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'pdf': 'application/pdf',
        'doc': 'application/msword',
        'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'txt': 'text/plain',
        'csv': 'text/csv',
      };

      final mimeType = mimeMap[extension];
      if (mimeType != null && allowedTypes.contains(mimeType)) {
        return null;
      }

      return 'mimes_validation';
    }

    return null;
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
      return 'max_file_size_validation';
    }

    // Check if it's a file first
    final fileRule = FileRule();
    if (fileRule.validate(field, value, arg, data: data) != null) {
      return 'max_file_size_validation';
    }

    final maxSize = int.tryParse(arg);
    if (maxSize == null) {
      return 'max_file_size_validation';
    }

    // In a real implementation, this would check the actual file size
    // For now, we'll assume the value contains size information or accept it
    if (value is Map && value.containsKey('size')) {
      final fileSize = value['size'];
      if (fileSize is int && fileSize > maxSize) {
        return 'max_file_size_validation';
      }
    }

    return null;
  }
}
