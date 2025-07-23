import '../../contracts/http/middleware_contract.dart';
import '../../types/handler.dart';

/// Represents a route in the application.
class Route {
  final String method;
  final String path;
  final Handler handler;
  final RegExp matcher;
  final List<String> paramNames;
  final List<Middleware> middleware;

  /// Checks if the route is dynamic (contains parameters).
  bool get isDynamic => path.contains(RegExp(r':\w+'));

  Route(this.method, this.path, this.handler, this.middleware)
      : matcher = _createMatcher(path),
        paramNames = _extractParamNames(path);

  static RegExp _createMatcher(String path) {
    final regex =
        path.replaceAllMapped(RegExp(r':(\w+)'), (m) => '(?<_${m[1]}>[^/]+)');
    return RegExp('^$regex\$');
  }

  static List<String> _extractParamNames(String path) {
    return RegExp(r':(\w+)').allMatches(path).map((m) => m.group(1)!).toList();
  }

  bool matches(String method, String path) {
    return this.method == method && matcher.hasMatch(path);
  }

  Map<String, String> extractParams(String path) {
    final match = matcher.firstMatch(path);
    if (match == null) return {};
    return {
      for (final name in paramNames) name: match.namedGroup('_$name') ?? ''
    };
  }
}
