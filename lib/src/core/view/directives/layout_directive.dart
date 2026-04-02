import 'dart:io';
import 'package:khadem/src/contracts/views/directive_contract.dart';
import '../../../support/utils/path_validator.dart';
import 'section_directive.dart';

class LayoutDirective implements ViewDirective {
  static final _layoutRegex = RegExp(r"""@layout\s*\(\s*["'](.+?)["']\s*\)""");
  static final _yieldRegex = RegExp(r"""@yield\s*\(\s*["'](.+?)["']\s*\)""");
  static const _viewsBasePath = 'resources/views';
  static final _pathValidator = PathValidator(_viewsBasePath);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final match = _layoutRegex.firstMatch(content);
    if (match == null) return content;

    final layoutFile = match.group(1)!;
    final filePath = '$layoutFile.khdm.html';

    // Validate and resolve the path (throws SecurityException if invalid)
    final safePath = _pathValidator.validateAndResolve(
      filePath,
      context: 'layout',
    );

    // Check if layout file exists
    final layoutFileExists = await File(safePath).exists();
    if (!layoutFileExists) {
      throw Exception('Layout file not found: $safePath');
    }

    final layoutContent = await File(safePath).readAsString();

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
}
