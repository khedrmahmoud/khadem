import '../../../contracts/views/directive_contract.dart';
import '../../http/request/request.dart';

/// Authentication and authorization directives
///
/// These directives integrate with the Khadem Request system to provide
/// real authentication and authorization checks.
///
/// Usage in controllers:
/// ```dart
/// return view('dashboard', context: {
///   'request': request,  // Pass the Request object
///   'user': request.user,
///   // ... other context data
/// });
/// ```
///
/// The directives will automatically use the Request object for authentication
/// checks when available, falling back to context-based checks for compatibility.
class AuthDirective implements ViewDirective {
  static final _authRegex = RegExp(r'@auth(.*?)@endauth', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_authRegex, (match) {
      final body = match.group(1)!.trim();

      // Check if user is authenticated
      final isAuthenticated = _isAuthenticated(context);

      return isAuthenticated ? body : '';
    });
  }

  bool _isAuthenticated(Map<String, dynamic> context) {
    // Try to get the request from context first
    final request = context['request'] as Request?;
    if (request != null) {
      return request.isAuthenticated;
    }

    // Fallback to checking if user exists in context
    return context.containsKey('user') && context['user'] != null;
  }
}

class GuestDirective implements ViewDirective {
  static final _guestRegex = RegExp(r'@guest(.*?)@endguest', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_guestRegex, (match) {
      final body = match.group(1)!.trim();

      // Check if user is not authenticated
      final isAuthenticated = _isAuthenticated(context);

      return !isAuthenticated ? body : '';
    });
  }

  bool _isAuthenticated(Map<String, dynamic> context) {
    // Try to get the request from context first
    final request = context['request'] as Request?;
    if (request != null) {
      return request.isAuthenticated;
    }

    // Fallback to checking if user exists in context
    return context.containsKey('user') && context['user'] != null;
  }
}

class CanDirective implements ViewDirective {
  static final _canRegex = RegExp(r'@can\s*\(\s*(.+?)\s*\)(.*?)@endcan', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_canRegex, (match) {
      final permission = match.group(1)!.trim();
      final body = match.group(2)!;

      // Check if user has permission
      final hasPermission = _hasPermission(permission, context);

      return hasPermission ? body : '';
    });
  }

  bool _hasPermission(String permission, Map<String, dynamic> context) {
    // Try to get the request from context first
    final request = context['request'] as Request?;
    if (request != null) {
      // For now, we'll check if the user has the permission in their data
      // In a real implementation, this might check against a permissions system
      final user = request.user;
      if (user != null) {
        final permissions = user['permissions'] as List<dynamic>?;
        return permissions?.contains(permission) ?? false;
      }
      return false;
    }

    // Fallback to checking permissions in context
    if (context.containsKey('permissions') && context['permissions'] is List) {
      final permissions = context['permissions'] as List;
      return permissions.contains(permission);
    }
    return false;
  }
}

class CannotDirective implements ViewDirective {
  static final _cannotRegex = RegExp(r'@cannot\s*\(\s*(.+?)\s*\)(.*?)@endcannot', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_cannotRegex, (match) {
      final permission = match.group(1)!.trim();
      final body = match.group(2)!;

      // Check if user does not have permission
      final hasPermission = _hasPermission(permission, context);

      return !hasPermission ? body : '';
    });
  }

  bool _hasPermission(String permission, Map<String, dynamic> context) {
    // Try to get the request from context first
    final request = context['request'] as Request?;
    if (request != null) {
      // For now, we'll check if the user has the permission in their data
      // In a real implementation, this might check against a permissions system
      final user = request.user;
      if (user != null) {
        final permissions = user['permissions'] as List<dynamic>?;
        return permissions?.contains(permission) ?? false;
      }
      return false;
    }

    // Fallback to checking permissions in context
    if (context.containsKey('permissions') && context['permissions'] is List) {
      final permissions = context['permissions'] as List;
      return permissions.contains(permission);
    }
    return false;
  }
}

class RoleDirective implements ViewDirective {
  static final _roleRegex = RegExp(r'@role\s*\(\s*(.+?)\s*\)(.*?)@endrole', dotAll: true);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_roleRegex, (match) {
      final role = match.group(1)!.trim();
      final body = match.group(2)!;

      // Check if user has role
      final hasRole = _hasRole(role, context);

      return hasRole ? body : '';
    });
  }

  bool _hasRole(String role, Map<String, dynamic> context) {
    // Try to get the request from context first
    final request = context['request'] as Request?;
    if (request != null) {
      return request.hasRole(role);
    }

    // Fallback to checking roles in context
    if (context.containsKey('roles') && context['roles'] is List) {
      final roles = context['roles'] as List;
      return roles.contains(role);
    }
    return false;
  }
}
