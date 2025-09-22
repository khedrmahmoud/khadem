import 'dart:async';

import 'package:khadem/src/contracts/views/directive_contract.dart';

/// CSRF token field directive
/// Replaces @csrf with a hidden input containing the CSRF token
class CsrfDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final token = context['csrf_token'] as String? ?? '';
    return content.replaceAllMapped(RegExp(r'@csrf'), (match) {
      return '<input type="hidden" name="csrf_token" value="$token">';
    });
  }
}

/// HTTP method override directive for forms
/// Replaces @method('VERB') with hidden _method input
class MethodDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(
      RegExp(r"@method\('([A-Za-z]+)'\)"),
      (match) {
        final method = match.group(1)?.toUpperCase() ?? '';
        return '<input type="hidden" name="_method" value="$method">';
      },
    );
  }
}

/// Old input value directive
/// Replaces @old('field') with previously submitted value
class OldDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final old = context['old'] as Map<String, dynamic>? ?? {};
    return content.replaceAllMapped(
      RegExp(r"@old\('([\w-]+)'\)"),
      (match) {
        final key = match.group(1) ?? '';
        final value = old[key] ?? '';
        return value.toString();
      },
    );
  }
}

/// Route URL generation directive (stub)
class RouteDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(
      RegExp(r"@route\('([^']+)'\)"),
      (match) {
        final routeName = match.group(1) ?? '';
        return routeName; // Replace with real route URL if available
      },
    );
  }
}

/// URL directive (stub)
class UrlDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(
      RegExp(r"@url\('([^']+)'\)"),
      (match) {
        final url = match.group(1) ?? '';
        return url;
      },
    );
  }
}

/// Action attribute directive (stub)
class ActionDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(
      RegExp(r"@action\('([^']+)'\)"),
      (match) {
        final action = match.group(1) ?? '';
        return action;
      },
    );
  }
}
