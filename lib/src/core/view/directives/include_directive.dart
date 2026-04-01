import 'dart:io';

import 'package:khadem/src/contracts/views/directive_contract.dart';
import 'package:path/path.dart' as p;
import '../security_exception.dart';

class IncludeDirective implements ViewDirective {
  static final _includeRegex = RegExp(r"""@include\(['\"](.*?)['\"]\)""");
  static const _viewsBasePath = 'resources/views';

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_includeRegex, (match) {
      final includeFile = match.group(1)!;

      // Validate and sanitize the include path to prevent path traversal
      if (!_isValidIncludePath(includeFile)) {
        throw SecurityException(
          'Invalid include path detected: $includeFile. '
          'Path traversal attempts are not allowed.',
        );
      }

      final path = p.join(_viewsBasePath, '$includeFile.khdm.html');
      final canonicalPath = _getCanonicalPath(path);

      // Ensure the canonical path is within the views directory
      if (!_isPathWithinViews(canonicalPath)) {
        throw SecurityException(
          'Include path must be within views directory: $includeFile',
        );
      }

      final file = File(canonicalPath);
      if (!file.existsSync()) return '';
      return file.readAsStringSync();
    });
  }

  /// Validates that the include path doesn't contain path traversal sequences
  bool _isValidIncludePath(String path) {
    // Reject paths containing path traversal sequences
    if (path.contains('..') || path.contains('//') || path.startsWith('/')) {
      return false;
    }

    // Reject absolute paths (Windows and Unix)
    if (path.contains(':') || path.startsWith(r'\')) {
      return false;
    }

    // Only allow alphanumeric, dots, underscores, hyphens, and forward slashes
    final validPattern = RegExp(r'^[a-zA-Z0-9_\-/\.]+$');
    return validPattern.hasMatch(path);
  }

  /// Gets the canonical (absolute, normalized) path
  String _getCanonicalPath(String path) {
    final file = File(path);
    try {
      return file.absolute.path;
    } catch (e) {
      return p.normalize(p.absolute(path));
    }
  }

  /// Ensures the path is within the views directory
  bool _isPathWithinViews(String canonicalPath) {
    final viewsDir = Directory(_viewsBasePath).absolute.path;
    final normalizedCanonical = p.normalize(canonicalPath);
    final normalizedViews = p.normalize(viewsDir);

    return normalizedCanonical.startsWith(normalizedViews);
  }
}
