import 'dart:convert';
import 'dart:io';

import '../../view/renderer.dart';
import 'response_body.dart';
import 'response_headers.dart';

/// Handles view rendering and template responses.
///
/// This class provides methods for rendering views and sending HTML content
/// with proper content type handling.
class ResponseRenderer {
  final ResponseBody _body;
  final ResponseHeaders _headers;

  ResponseRenderer(this._body, this._headers);

  /// Renders a view template and sends it as HTML response.
  Future<void> renderView(
    String viewName, {
    Map<String, dynamic> data = const {},
    int? statusCode,
  }) async {
    final renderer = ViewRenderer.instance;
    final content = await renderer.render(viewName, context: data);

    _headers.setContentType(ContentType.html);
    _body.sendHtml(content);
  }

  /// Sends raw HTML content.
  void sendHtml(String html, {int? statusCode}) {
    _body.sendHtml(html);
  }

  /// Renders a view template as a string without sending response.
  Future<String> renderToString(
    String viewName, {
    Map<String, dynamic> data = const {},
  }) async {
    final renderer = ViewRenderer.instance;
    return await renderer.render(viewName, context: data);
  }

  /// Sends a template with layout.
  Future<void> renderWithLayout(
    String viewName,
    String layoutName, {
    Map<String, dynamic> data = const {},
    Map<String, dynamic> layoutData = const {},
  }) async {
    final renderer = ViewRenderer.instance;

    // Render the main content
    final content = await renderer.render(viewName, context: data);

    // Render the layout with content injected
    final layoutContext = {
      ...layoutData,
      'content': content,
    };

    final fullContent = await renderer.render(layoutName, context: layoutContext);

    _headers.setContentType(ContentType.html);
    _body.sendHtml(fullContent);
  }

  /// Sends a partial view (component) as HTML.
  Future<void> renderPartial(
    String partialName, {
    Map<String, dynamic> data = const {},
  }) async {
    await renderView(partialName, data: data);
  }

  /// Renders JSON data using a view template.
  Future<void> renderJsonView(
    String viewName, {
    Map<String, dynamic> data = const {},
  }) async {
    final renderer = ViewRenderer.instance;
    final content = await renderer.render(viewName, context: data);

    // Try to parse as JSON, fallback to string if not valid JSON
    try {
      final jsonData = json.decode(content);
      _body.sendJson(jsonData);
    } catch (_) {
      // If not valid JSON, send as plain text
      _body.sendText(content);
    }
  }
}
