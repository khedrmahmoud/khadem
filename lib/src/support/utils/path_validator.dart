import 'dart:io';
import 'package:path/path.dart' as p;
import '../exceptions/security_exception.dart';

/// Validates file paths to prevent security vulnerabilities like path traversal.
class PathValidator {
  final String baseDirectory;

  PathValidator(this.baseDirectory);

  /// Validates and resolves a path, ensuring it stays within the base directory.
  ///
  /// Throws [SecurityException] if:
  /// - Path contains traversal sequences (.., //, etc.)
  /// - Path is absolute
  /// - Resolved path escapes the base directory
  String validateAndResolve(String relativePath, {required String context}) {
    // Validate the path doesn't contain dangerous patterns
    if (!_isValidPath(relativePath)) {
      throw SecurityException(
        'Invalid $context path detected: $relativePath. '
        'Path traversal attempts are not allowed.',
      );
    }

    // Build and canonicalize the full path
    final fullPath = p.join(baseDirectory, relativePath);
    final canonicalPath = _canonicalize(fullPath);

    // Ensure it stays within the base directory
    if (!_isWithinBaseDirectory(canonicalPath)) {
      throw SecurityException(
        '$context path must be within $baseDirectory: $relativePath',
      );
    }

    return canonicalPath;
  }

  /// Validates that a path doesn't contain dangerous patterns
  bool _isValidPath(String path) {
    // Reject path traversal sequences
    if (path.contains('..') || path.contains('//') || path.startsWith('/')) {
      return false;
    }

    // Reject absolute paths (Windows and Unix)
    if (path.contains(':') || path.startsWith(r'\')) {
      return false;
    }

    // Only allow safe characters: alphanumeric, dots, underscores, hyphens, slashes
    final validPattern = RegExp(r'^[a-zA-Z0-9_\-/\.]+$');
    return validPattern.hasMatch(path);
  }

  /// Gets the canonical (absolute, normalized) path
  String _canonicalize(String path) {
    try {
      return File(path).absolute.path;
    } catch (e) {
      return p.normalize(p.absolute(path));
    }
  }

  /// Ensures the canonical path is within the base directory
  bool _isWithinBaseDirectory(String canonicalPath) {
    final baseDir = Directory(baseDirectory).absolute.path;
    final normalizedCanonical = p.normalize(canonicalPath);
    final normalizedBase = p.normalize(baseDir);

    return normalizedCanonical.startsWith(normalizedBase);
  }
}
