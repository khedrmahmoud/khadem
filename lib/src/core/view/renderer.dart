// view_renderer.dart
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../support/exceptions/not_found_exception.dart';
import 'directive_registry.dart';

class ViewRenderer {
  final String viewsDirectory;
  static final ViewRenderer instance = ViewRenderer();

  ViewRenderer({this.viewsDirectory = 'resources/views'});

  Future<String> render(String viewName,
      {Map<String, dynamic> context = const {},}) async {
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
      return context[key]?.toString() ?? '';
    });

    return content;
  }
}
