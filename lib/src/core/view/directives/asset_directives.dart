import '../../../contracts/views/directive_contract.dart';

/// Asset management directives
class AssetDirective implements ViewDirective {
  static final _assetRegex = RegExp(r'@asset\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_assetRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      // In a real implementation, this would resolve the asset URL
      // For now, just return the path as-is
      return '/assets/$cleanPath';
    });
  }
}

class CssDirective implements ViewDirective {
  static final _cssRegex = RegExp(r'@css\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_cssRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      return '<link rel="stylesheet" href="/assets/css/$cleanPath">';
    });
  }
}

class JsDirective implements ViewDirective {
  static final _jsRegex = RegExp(r'@js\s*\(\s*(.+?)\s*\)');

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_jsRegex, (match) {
      final path = match.group(1)!.trim();

      // Remove quotes if present
      final cleanPath = path.replaceAll('"', '').replaceAll("'", '');

      return '<script src="/assets/js/$cleanPath"></script>';
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
