import '../../contracts/http/middleware_contract.dart';
import '../http/request/request_handler.dart';

/// Represents a route in the application.
class Route {
  final String method;
  final String path;
  final String? name;
  final RequestHandler handler;
  final RegExp matcher;
  final List<String> paramNames;
  final List<Middleware> middleware;

  /// Checks if the route is dynamic (contains parameters).
  bool get isDynamic => path.contains(RegExp(r':\w+'));

  /// Checks if the route has a name
  bool get isNamed => name != null && name!.isNotEmpty;

  Route(this.method, String path, this.handler, this.middleware, {this.name})
      : path = _normalizePath(path),
        matcher = _createMatcher(_normalizePath(path)),
        paramNames = _extractParamNames(path);

  /// Normalizes a path by removing trailing slashes
  /// Preserves root path '/' as-is
  static String _normalizePath(String path) {
    // Special case: root path
    if (path == '/' || path.isEmpty) {
      return '/';
    }
    
    // Remove trailing slash
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  static RegExp _createMatcher(String path) {
    final regex =
        path.replaceAllMapped(RegExp(r':(\w+)'), (m) => '(?<_${m[1]}>[^/]+)');
    return RegExp('^$regex\$');
  }

  static List<String> _extractParamNames(String path) {
    return RegExp(r':(\w+)').allMatches(path).map((m) => m.group(1)!).toList();
  }

  bool matches(String method, String path) {
    final normalizedPath = _normalizePath(path);
    return this.method == method && matcher.hasMatch(normalizedPath);
  }

  Map<String, String> extractParams(String path) {
    final normalizedPath = _normalizePath(path);
    final match = matcher.firstMatch(normalizedPath);
    if (match == null) return {};
    return {
      for (final name in paramNames) name: match.namedGroup('_$name') ?? '',
    };
  }
}
