import 'dart:convert';
import 'dart:io';

import '../../view/renderer.dart';
import '../context/request_context.dart';
import '../request/request.dart';
import 'response_body.dart';
import 'response_headers.dart';

/// Handles view rendering and template responses.
///
/// This class provides methods for rendering views and sending HTML content
/// with proper content type handling.
/// Handles view rendering and template responses with proper context management.
///
/// This class provides methods for rendering views and sending HTML content
/// while ensuring all necessary context data is available to the view,
/// including:
/// - Request object
/// - Session data
/// - CSRF token
/// - Flash messages
/// - Validation errors
/// - Old input
/// - Authentication status
class ResponseRenderer {
  final ResponseBody _body;
  final ResponseHeaders _headers;
  Request? _request;

  ResponseRenderer(this._body, this._headers) {
    // Request will be set via setRequest() when available
  }

  /// Sets the request object for the renderer
  void setRequest(Request request) {
    _request = request;
  }

  /// Builds the complete view context by combining:
  /// - User provided data
  /// - Request data (session, input, etc)
  /// - Framework data (csrf token, etc)
  Future<Map<String, dynamic>> _buildViewContext(
    Map<String, dynamic> userData,
  ) async {
    final context = <String, dynamic>{
      ...userData,
    };
    _request = RequestContext.request;
    if (_request != null) {
      // Add request object itself
      context['request'] = _request;

      // Add session data if available
      final session = _request!.attribute('session');
      if (session != null) {
        context['session'] = session;
      }

      // Add CSRF token
      final csrfToken = _request!.attribute('csrf_token');
      if (csrfToken != null) {
        context['csrf_token'] = csrfToken;
      }

      // Add flash messages
      final flash = _request!.attribute('flash');
      if (flash != null) {
        context['flash'] = flash;
      }

      // Add validation errors
      final errors = _request!.attribute('errors');
      if (errors != null) {
        context['errors'] = errors;
      }

      // Add old input
      final oldInput = await _request!.body;
      context['old'] = oldInput;

      // Add auth data
      final user = _request!.attribute('user');
      if (user != null) {
        context['user'] = user;
        context['auth'] = {'user': user};
      }
      context['authenticated'] = user != null;

      // Add request data
      context['input'] = _request!.params;
      context['query'] = _request!.raw.uri.queryParameters;
      context['method'] = _request!.method;
      context['path'] = _request!.raw.uri.path;
    }

    return context;
  }

  /// Renders a view template and sends it as HTML response.
  Future<void> renderView(
    String viewName, {
    Map<String, dynamic> data = const {},
    int? statusCode,
  }) async {
    final renderer = ViewRenderer.instance;
    final context = await _buildViewContext(data);
    final content = await renderer.render(viewName, context: context);

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
    final context = await _buildViewContext(data);
    return renderer.render(viewName, context: context);
  }

  /// Sends a template with layout.
  Future<void> renderWithLayout(
    String viewName,
    String layoutName, {
    Map<String, dynamic> data = const {},
    Map<String, dynamic> layoutData = const {},
  }) async {
    final renderer = ViewRenderer.instance;
    final viewContext = await _buildViewContext(data);

    // Render the main content
    final content = await renderer.render(viewName, context: viewContext);

    // Render the layout with content injected
    final layoutContext = await _buildViewContext({
      ...layoutData,
      'content': content,
    });

    final fullContent =
        await renderer.render(layoutName, context: layoutContext);

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
    final context = await _buildViewContext(data);
    final content = await renderer.render(viewName, context: context);

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
