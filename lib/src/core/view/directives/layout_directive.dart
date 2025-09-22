import 'dart:io';
import 'package:khadem/khadem.dart';

class LayoutDirective implements ViewDirective {
  static final _layoutRegex = RegExp(r"""@layout\s*\(\s*["'](.+?)["']\s*\)""");
  static final _yieldRegex = RegExp(r"""@yield\s*\(\s*["'](.+?)["']\s*\)""");

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final match = _layoutRegex.firstMatch(content);
    if (match == null) return content;

    final layoutFile = match.group(1)!;
    final layoutPath = 'resources/views/$layoutFile.khdm.html';

    // Check if layout file exists
    final layoutFileExists = await File(layoutPath).exists();
    if (!layoutFileExists) {
      throw Exception('Layout file not found: $layoutPath');
    }

    final layoutContent = await File(layoutPath).readAsString();

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
