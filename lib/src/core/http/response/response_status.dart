import 'dart:io';

/// Handles HTTP response status codes with convenient methods and constants.
///
/// This class provides a clean API for setting HTTP status codes with
/// descriptive names and common status code constants.
class ResponseStatus {
  final HttpResponse _response;

  ResponseStatus(this._response);

  /// Sets the HTTP status code.
  void setStatus(int code) {
    _response.statusCode = code;
  }

  /// Gets the current status code.
  int get statusCode => _response.statusCode;

  /// Sets status to 200 OK.
  void ok() => setStatus(200);

  /// Sets status to 201 Created.
  void created() => setStatus(201);

  /// Sets status to 202 Accepted.
  void accepted() => setStatus(202);

  /// Sets status to 204 No Content.
  void noContent() => setStatus(204);

  /// Sets status to 301 Moved Permanently.
  void movedPermanently() => setStatus(301);

  /// Sets status to 302 Found (temporary redirect).
  void found() => setStatus(302);

  /// Sets status to 303 See Other.
  void seeOther() => setStatus(303);

  /// Sets status to 304 Not Modified.
  void notModified() => setStatus(304);

  /// Sets status to 307 Temporary Redirect.
  void temporaryRedirect() => setStatus(307);

  /// Sets status to 308 Permanent Redirect.
  void permanentRedirect() => setStatus(308);

  /// Sets status to 400 Bad Request.
  void badRequest() => setStatus(400);

  /// Sets status to 401 Unauthorized.
  void unauthorized() => setStatus(401);

  /// Sets status to 403 Forbidden.
  void forbidden() => setStatus(403);

  /// Sets status to 404 Not Found.
  void notFound() => setStatus(404);

  /// Sets status to 405 Method Not Allowed.
  void methodNotAllowed() => setStatus(405);

  /// Sets status to 409 Conflict.
  void conflict() => setStatus(409);

  /// Sets status to 410 Gone.
  void gone() => setStatus(410);

  /// Sets status to 422 Unprocessable Entity.
  void unprocessableEntity() => setStatus(422);

  /// Sets status to 429 Too Many Requests.
  void tooManyRequests() => setStatus(429);

  /// Sets status to 500 Internal Server Error.
  void internalServerError() => setStatus(500);

  /// Sets status to 501 Not Implemented.
  void notImplemented() => setStatus(501);

  /// Sets status to 502 Bad Gateway.
  void badGateway() => setStatus(502);

  /// Sets status to 503 Service Unavailable.
  void serviceUnavailable() => setStatus(503);

  /// Sets status to 504 Gateway Timeout.
  void gatewayTimeout() => setStatus(504);

  /// Checks if the status code indicates success (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Checks if the status code indicates redirection (3xx).
  bool get isRedirection => statusCode >= 300 && statusCode < 400;

  /// Checks if the status code indicates client error (4xx).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Checks if the status code indicates server error (5xx).
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Gets a descriptive message for the current status code.
  String getStatusMessage() {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 204:
        return 'No Content';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 303:
        return 'See Other';
      case 304:
        return 'Not Modified';
      case 307:
        return 'Temporary Redirect';
      case 308:
        return 'Permanent Redirect';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 409:
        return 'Conflict';
      case 410:
        return 'Gone';
      case 422:
        return 'Unprocessable Entity';
      case 429:
        return 'Too Many Requests';
      case 500:
        return 'Internal Server Error';
      case 501:
        return 'Not Implemented';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        return 'Unknown Status';
    }
  }
}
