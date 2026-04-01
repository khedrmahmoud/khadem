import 'dart:io';
import 'package:khadem/src/contracts/views/directive_contract.dart';
import 'package:path/path.dart' as p;
import '../security_exception.dart';
import 'section_directive.dart';

class LayoutDirective implements ViewDirective {
  static final _layoutRegex = RegExp(r"""@layout\s*\(\s*["'](.+?)["']\s*\)""");
  static final _yieldRegex = RegExp(r"""@yield\s*\(\s*["'](.+?)["']\s*\)""");
  static const _viewsBasePath = 'resources/views';

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final match = _layoutRegex.firstMatch(content);
    if (match == null) return content;

    final layoutFile = match.group(1)!;

    // Validate and sanitize the layout path to prevent path traversal
    if (!_isValidLayoutPath(layoutFile)) {
      throw SecurityException(
        'Invalid layout path detected: $layoutFile. '
        'Path traversal attempts are not allowed.',
      );
    }

    final layoutPath = '$_viewsBasePath/$layoutFile.khdm.html';
    final canonicalPath = _getCanonicalPath(layoutPath);

    // Ensure the canonical path is within the views directory
    if (!_isPathWithinViews(canonicalPath)) {
      throw SecurityException(
        'Layout path must be within views directory: $layoutFile',
      );
    }

    // Check if layout file exists
    final layoutFileExists = await File(canonicalPath).exists();
    if (!layoutFileExists) {
      throw Exception('Layout file not found: $canonicalPath');
    }

    final layoutContent = await File(canonicalPath).readAsString();

    // Remove the @layout directive
    final contentWithoutLayout = content.replaceFirst(_layoutRegex, '');

    // Extract sections using SectionDirective
    final sectionDirective = SectionDirective();
    final sections = sectionDirective.extractSections(contentWithoutLayout);

    // Replace all @yield('key') in layout with matching section
    final rendered = layoutContent.replaceAllMapped(_yieldRegex, (m) {
      final key = m.group(1)!;
      return sections[key] ?? '';
    });

    return rendered;
  }

  /// Validates that the layout path doesn't contain path traversal sequences
  bool _isValidLayoutPath(String path) {
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
