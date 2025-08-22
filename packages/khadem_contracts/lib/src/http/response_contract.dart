/// HTTP response contract that defines the required methods for response handling
abstract class ResponseContract {
  /// Set the response status code
  set statusCode(int code);

  /// Get the response status code
  int get statusCode;

  /// Set response headers
  void headers(Map<String, String> headers);

  /// Set a single response header
  void header(String name, String value);

  /// Set the response content type
  void contentType(String contentType);

  /// Write response body
  void write(dynamic body);

  /// Send a JSON response
  void json(dynamic data);

  /// Send a text response
  void text(String content);

  /// Send a file response
  Future<void> file(String path);

  /// Send a download response
  Future<void> download(String path, [String? filename]);

  /// Redirect to another URL
  void redirect(String url, [int status = 302]);

  /// End the response
  void end();
}
