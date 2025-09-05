// view_renderer.dart
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../support/exceptions/not_found_exception.dart';
import 'directive_registry.dart';

class ViewRenderer {
  final String viewsDirectory;
  static final ViewRenderer instance = ViewRenderer();
  final bool _autoEscape;

  ViewRenderer({
    this.viewsDirectory = 'resources/views',
    bool autoEscape = true,
  }) : _autoEscape = autoEscape;

  Future<String> render(String viewName,
      {Map<String, dynamic> context = const {},
      bool escapeOutput = true,}) async {
    final path = p.join(viewsDirectory, '$viewName.khdm.html');
    final file = File(path);

    if (!await file.exists()) {
      throw NotFoundException('View file not found: $path');
    }

    String content = await file.readAsString();

    // Apply all registered directives
    content = await DirectiveRegistry.applyAll(content, context);

    // Finally replace variables like {{ user }}
    final variableRegex = RegExp(r'{{\s*(\w+)\s*}}');
    content = content.replaceAllMapped(variableRegex, (match) {
      final key = match.group(1)!;
      final value = context[key]?.toString() ?? '';

      // Auto-escape output to prevent XSS
      if (escapeOutput && _autoEscape) {
        return _escapeHtml(value);
      }

      return value;
    });

    // Also handle unescaped variables {{{ user }}}
    final unescapedVariableRegex = RegExp(r'{{{\s*(\w+)\s*}}}');
    content = content.replaceAllMapped(unescapedVariableRegex, (match) {
      final key = match.group(1)!;
      return context[key]?.toString() ?? '';
    });

    return content;
  }

  /// Escapes HTML entities to prevent XSS attacks
  String _escapeHtml(String input) {
    if (input.isEmpty) return input;

    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Renders a view without escaping (use with caution!)
  Future<String> renderUnsafe(String viewName,
      {Map<String, dynamic> context = const {}}) async {
    return render(viewName, context: context, escapeOutput: false);
  }
}
