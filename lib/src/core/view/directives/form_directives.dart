import '../../../contracts/views/directive_contract.dart';

/// Form and security directives
class CsrfDirective implements ViewDirective {
  static final _csrfRegex = RegExp(r'@csrf');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_csrfRegex, (match) {
      // In a real implementation, this would generate a CSRF token
      // For now, return a placeholder
      const token = 'csrf_token_placeholder';
      return '<input type="hidden" name="_token" value="$token">';
    });
  }
}

class MethodDirective implements ViewDirective {
  static final _methodRegex = RegExp(r'@method\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_methodRegex, (match) {
      final method = match.group(1)!.trim();

      // Remove quotes if present
      final cleanMethod = method.replaceAll('"', '').replaceAll("'", '');

      return '<input type="hidden" name="_method" value="$cleanMethod">';
    });
  }
}

class RouteDirective implements ViewDirective {
  static final _routeRegex = RegExp(r'@route\s*\(\s*(.+?)\s*(?:,\s*(.+?)\s*)?\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_routeRegex, (match) {
      final routeName = match.group(1)!.trim();
      final parameters = match.group(2)?.trim();

      // Remove quotes if present
      final cleanRouteName = routeName.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would resolve the route URL
      // For now, return a placeholder
      return '/route/$cleanRouteName${parameters != null ? '?$parameters' : ''}';
    });
  }
}

class UrlDirective implements ViewDirective {
  static final _urlRegex = RegExp(r'@url\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_urlRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would generate a full URL
      // For now, return the path as-is
      return cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    });
  }
}

class ActionDirective implements ViewDirective {
  static final _actionRegex = RegExp(r'@action\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_actionRegex, (match) {
      final action = match.group(1)!.trim();

      // Remove quotes if present
      final cleanAction = action.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would resolve the action URL
      // For now, return a placeholder
      return '/action/$cleanAction';
    });
  }
}
