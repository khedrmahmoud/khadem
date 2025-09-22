// view_renderer.dart
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../support/exceptions/not_found_exception.dart';
import 'directive_registry.dart';
import 'expression_evaluator.dart';
import 'html_escaper.dart';

class ViewRenderer {
  final String viewsDirectory;
  final ExpressionEvaluator _expressionEvaluator;
  final HtmlEscaper _htmlEscaper;
  final bool _autoEscape;

  static final ViewRenderer instance = ViewRenderer._internal();

  ViewRenderer._internal({
    String viewsDirectory = 'resources/views',
    bool autoEscape = true,
  })  : viewsDirectory = viewsDirectory,
        _autoEscape = autoEscape,
        _expressionEvaluator = ExpressionEvaluator(),
        _htmlEscaper = HtmlEscaper();

  factory ViewRenderer({
    String viewsDirectory = 'resources/views',
    bool autoEscape = true,
  }) {
    return ViewRenderer._internal(
      viewsDirectory: viewsDirectory,
      autoEscape: autoEscape,
    );
  }

  Future<String> render(
    String viewName, {
    Map<String, dynamic> context = const {},
    bool escapeOutput = true,
  }) async {
    final template = await _loadTemplate(viewName);
    final processedTemplate = await _applyDirectives(template, context);
    return _renderExpressions(processedTemplate, context, escapeOutput);
  }

  /// Loads a template file from the views directory
  Future<String> _loadTemplate(String viewName) async {
    final path = p.join(viewsDirectory, '$viewName.khdm.html');
    final file = File(path);

    if (!await file.exists()) {
      throw NotFoundException('View file not found: $path');
    }

    return file.readAsString();
  }

  /// Applies all registered directives to the template
  Future<String> _applyDirectives(
    String template,
    Map<String, dynamic> context,
  ) async {
    return DirectiveRegistry.applyAll(template, context);
  }

  /// Renders expressions in the template
  String _renderExpressions(
    String template,
    Map<String, dynamic> context,
    bool escapeOutput,
  ) {
    // Handle escaped expressions {{ expression }}
    final escapedRegex = RegExp(r'{{\s*([^}]+?)\s*}}');
    template = template.replaceAllMapped(escapedRegex, (match) {
      final expression = match.group(1)!.trim();
      final value = _expressionEvaluator.evaluate(expression, context);
      final stringValue = value?.toString() ?? '';

      return escapeOutput && _autoEscape
          ? _htmlEscaper.escape(stringValue)
          : stringValue;
    });

    // Handle unescaped expressions {{{ expression }}}
    final unescapedRegex = RegExp(r'{{{\s*([^}]+?)\s*}}}');
    template = template.replaceAllMapped(unescapedRegex, (match) {
      final expression = match.group(1)!.trim();
      final value = _expressionEvaluator.evaluate(expression, context);
      return value?.toString() ?? '';
    });

    return template;
  }

  /// Renders a view without escaping (use with caution!)
  Future<String> renderUnsafe(
    String viewName, {
    Map<String, dynamic> context = const {},
  }) async {
    return render(viewName, context: context, escapeOutput: false);
  }

  /// Public access to expression evaluator for testing
  dynamic evaluateExpression(String expression, Map<String, dynamic> context) {
    return _expressionEvaluator.evaluate(expression, context);
  }
}
