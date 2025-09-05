import 'package:khadem/src/contracts/views/directive_contract.dart';

import '../../../application/khadem.dart';


/// Form and security directives
class CsrfDirective implements ViewDirective {
  static final _csrfRegex = RegExp(r'@csrf');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_csrfRegex, (match) {
      // Try to get CSRF token from context first
      final csrfToken = context['csrf_token'] as String? ??
                       context['_token'] as String?;

      if (csrfToken != null) {
        return '<input type="hidden" name="_token" value="$csrfToken">';
      }

      // Generate a new token if none exists
      final token = _generateCsrfToken();
      return '<input type="hidden" name="_token" value="$token">';
    });
  }

  String _generateCsrfToken() {
    // In a real implementation, this would use a secure random generator
    // and store the token in the session
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 1000000;
    return 'csrf_${timestamp}_$random';
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

      // Parse parameters if provided
      Map<String, String> routeParams = {};
      if (parameters != null) {
        routeParams = _parseParameters(parameters);
      }

      // Try to use URL service if available
      try {
        return Khadem.urlService.route(cleanRouteName, parameters: routeParams);
      } catch (e) {
        // Fall back to basic implementation
      }

      // Fallback implementation
      return '/route/$cleanRouteName${parameters != null ? '?$parameters' : ''}';
    });
  }

  Map<String, String> _parseParameters(String params) {
    final paramMap = <String, String>{};
    final paramPairs = params.split(',');

    for (final pair in paramPairs) {
      final trimmed = pair.trim();
      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll('"', '').replaceAll("'", '');
          final value = parts[1].trim().replaceAll('"', '').replaceAll("'", '');
          paramMap[key] = value;
        }
      }
    }

    return paramMap;
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

      // Try to use URL service if available
      try {
        return Khadem.urlService.url(cleanPath);
      } catch (e) {
        // Fall back to basic implementation
      }

      // Fallback implementation
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

      // Check if it's a controller action (Controller@method)
      if (cleanAction.contains('@')) {
        final parts = cleanAction.split('@');
        if (parts.length == 2) {
          final controller = parts[0];
          final method = parts[1];

          // Try to find the route for this controller action
          try {
            // Look for named routes that match this controller action
            final namedRoutes = Khadem.urlService.namedRoutes;
            for (final entry in namedRoutes.entries) {
              final routeName = entry.key;

              // Check if this route matches the controller action
              // This is a simplified check - in a real implementation,
              // you'd have route metadata about controller actions
              if (routeName.contains(controller.toLowerCase()) &&
                  routeName.contains(method.toLowerCase())) {
                return Khadem.urlService.route(routeName);
              }
            }
          } catch (e) {
            // Fall back to basic implementation
          }

          // Fallback: generate a URL based on controller and method
          return '/${controller.toLowerCase()}/${method.toLowerCase()}';
        }
      }

      // For simple actions, try to use URL service
      try {
        return Khadem.urlService.url(cleanAction);
      } catch (e) {
        // Fall back to basic implementation
      }

      // Final fallback
      return '/action/$cleanAction';
    });
  }
}
