import 'core/static_handler.dart';

/// Handles static file serving configuration for the server.
class ServerStatic {
  ServerStaticHandler? _staticHandler;

  ServerStaticHandler? get staticHandler => _staticHandler;

  /// Configures static file serving from a given path.
  ///
  /// Example:
  /// ```dart
  /// serverStatic.serveStatic('public');
  /// ```
  void serveStatic(String path) {
    _staticHandler = ServerStaticHandler(path);
  }

  /// Clears the static file handler.
  void clear() {
    _staticHandler = null;
  }
}
