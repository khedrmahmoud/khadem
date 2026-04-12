import 'dart:async';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:mime/mime.dart';
import '../../contracts/validation/rule.dart';
import '../../core/http/request/uploaded_file.dart';

/// Validates that the field is an [UploadedFile].
///
/// Signature: `file`
///
/// Examples:
/// - `file`
class FileRule extends Rule {
  @override
  String get signature => 'file';

  @override
  String message(ValidationContext context) {
    final value = context.value;
    if (value is List<UploadedFile> && value.isEmpty) {
      return 'file_required_validation';
    }
    // Check for specific filename errors if we could pass context info,
    // but generic 'file_validation' is okay, or we can add specific errors.
    return 'file_validation';
  }

  /// Checks if the filename is safe.
  bool _isFilenameSafe(String filename) {
    // 1. Block null bytes
    if (filename.contains('\u0000')) return false;

    // 2. Block directory traversal
    if (filename.contains('..')) return false;

    // 3. Block ridiculously long filenames (255 chars is standard max)
    if (filename.length > 255) return false;

    // 4. Validate characters (allow alphanumeric, dot, dash, underscore, space, parenthesis)
    // Strict mode: r'^[a-zA-Z0-9._\-\(\) ]+$'
    // We'll be reasonably strict to prevent shell injection or weirdness.
    final safeRegex = RegExp(r'^[a-zA-Z0-9._\-\(\) ]+$');
    return safeRegex.hasMatch(filename);
  }

  // Override passes to include filename check
  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;

    if (value is UploadedFile) {
      return _isFilenameSafe(value.filename);
    }

    if (value is List<UploadedFile>) {
      if (value.isEmpty) {
        return false; // Default Required-like behavior? No, FileRule implies "is a valid file".
      }
      return value.every((f) => _isFilenameSafe(f.filename));
    }

    return false;
  }
}

/// Validates that the file is an image.
///
/// Uses magic numbers (header bytes) to verify the actual file type,
/// not just the extension or client-provided content type.
///
/// Signature: `image`
///
/// Examples:
/// - `image`
class ImageRule extends Rule {
  @override
  String get signature => 'image';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final value = context.value;
    if (value == null) return false;

    if (!await FileRule().passes(context)) return false;

    final allowedMimes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/webp',
      'image/svg+xml',
    ];

    if (value is UploadedFile) {
      return _isImage(value, allowedMimes);
    }

    if (value is List<UploadedFile>) {
      for (final file in value) {
        if (!await _isImage(file, allowedMimes)) return false;
      }
    }
    return true;
  }

  Future<bool> _isImage(UploadedFile file, List<String> allowedMimes) async {
    final mimeType = await _sniffMimeType(file);
    return mimeType != null && allowedMimes.contains(mimeType);
  }

  @override
  String message(ValidationContext context) => 'image_validation';
}

/// Validates that the file matches one of the given MIME types or extensions.
///
/// Securely checks magic numbers where possible.
///
/// Signature: `mimes:type1,type2,...`
///
/// Examples:
/// - `mimes:jpg,png,webp`
/// - `mimes:application/pdf,image/png`
class MimesRule extends Rule implements RuleMessageParametersProvider {
  final List<String>? _types;
  MimesRule([this._types]);

  @override
  String get signature => 'mimes';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final args = context.parameters;
    final value = context.value;
    final allowedTypes =
        _types?.map((e) => e.trim().toLowerCase()).toList() ??
        args.map((e) => e.trim().toLowerCase()).toList();

    if (value == null || allowedTypes.isEmpty) return false;

    if (!await FileRule().passes(context)) return false;

    if (value is UploadedFile) {
      return _validateMime(value, allowedTypes);
    } else if (value is List<UploadedFile>) {
      for (final item in value) {
        if (!await _validateMime(item, allowedTypes)) return false;
      }
    }
    return true;
  }

  Future<bool> _validateMime(UploadedFile file, List<String> allowed) async {
    // 1. Sniff MIME type from content (Magic Numbers)
    final snifferMime = await _sniffMimeType(file);

    // If we can't determine mime, fail secure? Or allow if extension matches?
    // Strong security: Fail if we can't identify it.
    if (snifferMime == null) return false;

    // 2. Consistency Check: Extension vs Content match
    // Prevent "image.png" (actual exe)
    final extMime = lookupMimeType(file.filename);

    // If extension has a known mime, it MUST match the sniffed mime.
    // Exception: Generic types like application/octet-stream or text/plain subtleties.
    // But for images/pdfs, they should match.
    if (extMime != null && snifferMime != extMime) {
      // Allow specific compatible mismatches if needed (e.g. jpg vs jpeg)
      // But lookupMimeType handles common aliases usually.
      // Special case: text/plain vs text/csv etc might overlap.
      // If extension implies distinct mime, and sniff allows it?

      // Strict Check:
      // If I upload 'malware.exe' renamed to 'report.pdf' ->
      // extMime='application/pdf', snifferMime='application/x-dosexec'.
      // Mismatch -> Block.

      // If I upload 'text.csv' -> extMime='text/csv', snifferMime='text/plain'.
      // This is a common failure point. CSV is text.
      // So we allow if sniffer is 'text/plain' and ext is text-based?
      // Or we just rely on the 'allowed' list being checked against sniffed.

      // THE USER ASKED FOR STRONGER SECURITY.
      // Blocking mismatched extension/content is the strongest move.
      // We can relax for text/* types.
      final isText =
          snifferMime.startsWith('text/') && extMime.startsWith('text/');
      if (!isText && snifferMime != extMime) {
        return false;
      }
    }

    // 3. Check against allowed list
    if (allowed.contains(snifferMime)) return true;

    // 4. Check extensions mapping (if allowed list contains extensions)
    // But we strictly validate against SNIFFED mime now.
    // So we iterate allowed extensions, convert to mime, and check matches sniffed.
    for (final type in allowed) {
      if (!type.contains('/')) {
        // It's an extension
        final expectedMime = lookupMimeType('file.$type');
        if (expectedMime == snifferMime) return true;
      }
    }

    return false;
  }

  @override
  String message(ValidationContext context) => 'invalid_file_type_validation';

  @override
  Map<String, dynamic> messageParameters(ValidationContext context) {
    final args = context.parameters;
    final allowedTypes =
        _types?.map((e) => e.trim()).toList() ??
        args.map((e) => e.trim()).toList();

    return {'values': allowedTypes.join(', ')};
  }
}

/// Validates that the file size is less than or equal to [maxSize] (in kilobytes).
///
/// Signature: `max_file_size:kilobytes`
///
/// Examples:
/// - `max_file_size:2048`
class MaxFileSizeRule extends Rule {
  @override
  String get signature => 'max_file_size';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;

    if (!await FileRule().passes(context)) return false;

    final maxKB = int.tryParse(args[0]);
    if (maxKB == null) return false;
    final maxBytes = maxKB * 1024;

    if (value is UploadedFile) {
      return value.size <= maxBytes;
    }
    if (value is List<UploadedFile>) {
      return value.every((file) => file.size <= maxBytes);
    }
    return true;
  }

  @override
  String message(ValidationContext context) {
    final value = context.value;
    if (value is List<UploadedFile> && value.length > 1) {
      return 'files_too_large_validation';
    }
    return 'file_too_large_validation';
  }
}

/// Validates that the file size is greater than or equal to [minSize] (in kilobytes).
///
/// Signature: `min_file_size:kilobytes`
///
/// Examples:
/// - `min_file_size:10`
class MinFileSizeRule extends Rule {
  @override
  String get signature => 'min_file_size';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;

    if (!await FileRule().passes(context)) return false;

    final minKB = int.tryParse(args[0]);
    if (minKB == null) return false;
    final minBytes = minKB * 1024;

    if (value is UploadedFile) {
      return value.size >= minBytes;
    }
    if (value is List<UploadedFile>) {
      return value.every((file) => file.size >= minBytes);
    }
    return true;
  }

  @override
  String message(ValidationContext context) {
    final value = context.value;
    if (value is List<UploadedFile> && value.length > 1) {
      return 'files_too_small_validation';
    }
    return 'file_too_small_validation';
  }
}

// --- Helpers ---

/// Reads file header bytes and sniffs the MIME type securely.
Future<String?> _sniffMimeType(UploadedFile file) async {
  try {
    List<int> headerBytes;

    if (file.isDiskBased && file.tempPath != null) {
      // Read first 12 bytes from disk
      final f = File(file.tempPath!);
      if (!await f.exists()) return null;
      headerBytes = await f.openRead(0, 12).first;
    } else {
      // Memory based - take from data
      final data = file.data;
      if (data.isEmpty) return null;
      headerBytes = data.take(12).toList();
    }

    // Sniff using mime package
    // We pass the filename to help disambiguate (e.g. valid XML could be svg or xml)
    // But header bytes take precedence.
    return lookupMimeType(file.filename, headerBytes: headerBytes);
  } catch (e) {
    return null;
  }
}
