import '../../routing/router.dart';
import '../context/request_context.dart';
import '../context/response_context.dart';
import '../request/request.dart';
import '../response/response.dart';

/// Base controller class for handling HTTP requests.
///
/// Provides convenient access to request and response objects,
/// as well as helper methods for common tasks like sending JSON responses,
/// rendering views, and validating input.
abstract class Controller {
  /// The current request context.
  Request get request => RequestContext.request;

  /// The current response context.
  Response get response => ResponseContext.response;

  /// Registers routes for this controller.
  ///
  /// Override this method to define routes using the provided [router].
  void registerRoutes(Router router) {}

  /// Sends a JSON response.
  void json(Map<String, dynamic> data, {int status = 200}) {
    response.status(status).sendJson(data);
  }

  /// Renders a view.
  Future<void> view(String name, [Map<String, dynamic> data = const {}]) async {
    await response.view(name, data: data);
  }

  /// Sends a plain text response.
  void send(String text, {int status = 200}) {
    response.status(status).send(text);
  }

  /// Validates the request input.
  ///
  /// Throws [ValidationException] if validation fails.
  Future<Map<String, dynamic>> validate(
    Map<String, String> rules, {
    Map<String, String> messages = const {},
  }) async {
    return request.validator.validateBody(rules, messages: messages);
  }
}
