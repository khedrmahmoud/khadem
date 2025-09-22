/// Handles authentication-related functionality for requests.
class RequestAuth {
  final Map<String, dynamic> _attributes;

  RequestAuth(this._attributes);

  /// Returns the currently authenticated user (if any).
  Map<String, dynamic>? get user =>
      _attributes['user'] as Map<String, dynamic>?;

  /// Returns the ID of the authenticated user (if available).
  dynamic get userId => user?['id'];

  /// Returns true if a user is authenticated.
  bool get isAuthenticated => user != null;

  /// Returns true if no user is authenticated.
  bool get isGuest => user == null;

  /// Sets the authenticated user.
  void setUser(Map<String, dynamic> userData) {
    _attributes['user'] = userData;
  }

  /// Clears the authenticated user.
  void clearUser() {
    _attributes.remove('user');
  }

  /// Checks if the user has a specific role.
  bool hasRole(String role) {
    final user = this.user;
    if (user == null) return false;

    final roles = user['roles'];
    if (roles is List<dynamic>) {
      return roles.contains(role);
    }
    // If roles is not a list, treat as no roles
    return false;
  }

  /// Checks if the user has any of the specified roles.
  bool hasAnyRole(List<String> roles) {
    return roles.any(hasRole);
  }

  /// Checks if the user has all of the specified roles.
  bool hasAllRoles(List<String> roles) {
    return roles.every(hasRole);
  }
}
