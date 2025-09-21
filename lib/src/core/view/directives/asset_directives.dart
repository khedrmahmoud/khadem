import 'package:khadem/src/contracts/views/directive_contract.dart';
import '../../../support/services/url_service.dart';

/// Asset management directives
class AssetDirective implements ViewDirective {
  final UrlService? _urlService;

  AssetDirective([this._urlService]);

  static final _assetRegex = RegExp(r'@asset\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_assetRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      // Use URL service if available, otherwise fallback to basic path
      if (_urlService != null) {
        return _urlService!.asset(cleanPath);
      } else {
        return '/assets/$cleanPath';
      }
    });
  }
}

class CssDirective implements ViewDirective {
  final UrlService? _urlService;

  CssDirective([this._urlService]);

  static final _cssRegex = RegExp(r'@css\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_cssRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      if (_urlService != null) {
        return '<link rel="stylesheet" href="${_urlService!.css(cleanPath)}">';
      } else {
        return '<link rel="stylesheet" href="/assets/css/$cleanPath">';
      }
    });
  }
}

class JsDirective implements ViewDirective {
  final UrlService? _urlService;

  JsDirective([this._urlService]);

  static final _jsRegex = RegExp(r'@js\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_jsRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      if (_urlService != null) {
        return '<script src="${_urlService!.js(cleanPath)}"></script>';
      } else {
        return '<script src="/assets/js/$cleanPath"></script>';
      }
    });
  }
}

class InlineCssDirective implements ViewDirective {
  static final _inlineCssRegex = RegExp(r'@inlineCss\s*\(\s*(.+?)\s*\)(.*?)@endInlineCss', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_inlineCssRegex, (match) {
      final media = match.group(1)?.trim() ?? '';
      final cssContent = match.group(2)!.trim();

      final mediaAttr = media.isNotEmpty ? ' media="$media"' : '';
      return '<style$mediaAttr>$cssContent</style>';
    });
  }
}

class InlineJsDirective implements ViewDirective {
  static final _inlineJsRegex = RegExp(r'@inlineJs\s*\(\s*(.+?)\s*\)(.*?)@endInlineJs', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_inlineJsRegex, (match) {
      final type = match.group(1)?.trim() ?? 'text/javascript';
      final jsContent = match.group(2)!.trim();

      return '<script type="$type">$jsContent</script>';
    });
  }
}

class UrlRouteDirective implements ViewDirective {
  final UrlService? _urlService;

  UrlRouteDirective([this._urlService]);

  static final _routeRegex = RegExp(r'@route\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_routeRegex, (match) {
      final args = match.group(1)!.trim();

      // Parse route name and parameters
      final parts = _parseRouteArgs(args);
      final routeName = parts['name']!;
      final parameters = parts['params'] ?? {};

      try {
        if (_urlService != null) {
          return _urlService!.route(routeName, parameters: parameters);
        } else {
          // Fallback: return the route path directly
          return '/$routeName';
        }
      } catch (e) {
        // Return original directive if route not found
        return match.group(0)!;
      }
    });
  }

  Map<String, dynamic> _parseRouteArgs(String args) {
    // Remove quotes from route name
    final cleanArgs = args.replaceAll('"', '').replaceAll("'", '');

    // Check if there are parameters
    final paramStart = cleanArgs.indexOf(',');
    if (paramStart == -1) {
      return {'name': cleanArgs.trim()};
    }

    final name = cleanArgs.substring(0, paramStart).trim();
    final paramString = cleanArgs.substring(paramStart + 1).trim();

    // Parse parameters (simple implementation)
    final params = <String, String>{};
    final paramPairs = paramString.split(',');
    for (final pair in paramPairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        params[keyValue[0].trim()] = keyValue[1].trim();
      }
    }

    return {'name': name, 'params': params};
  }
}
