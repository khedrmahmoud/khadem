import '../../core/http/request/request.dart';
import 'core/request_auth.dart';

/// Auth facade providing convenient access to authentication functionality
///
/// This class serves as the main entry point for authentication operations
/// within the Khadem framework. It provides a simple, fluent API for
/// checking authentication status and accessing user information.
///
/// Example usage:
/// ```dart
/// // In a controller or middleware
/// final auth = Auth(request);
///
/// if (auth.check) {
///   final user = auth.user;
///   final userId = auth.id;
///   // User is authenticated
/// } else if (auth.guest) {
///   // User is a guest
/// }
/// ```
class Auth {
  /// The HTTP request instance containing authentication context
  final Request? _request;

  /// Creates an Auth instance with an optional request context
  ///
  /// [request] The HTTP request containing user authentication data.
  /// If null, all authentication checks will return false/guest status.
  Auth([this._request]);

  /// Gets the authenticated user data
  ///
  /// Returns the user information from the request if authenticated,
  /// otherwise returns null.
  Map<String, dynamic>? get user => _request?.user;

  /// Gets the authenticated user's ID
  ///
  /// Returns the user ID from the request if authenticated,
  /// otherwise returns null.
  dynamic get id => _request?.userId;

  /// Checks if the current request has an authenticated user
  ///
  /// Returns true if the user is authenticated, false otherwise.
  bool get check => _request?.isAuthenticated ?? false;

  /// Checks if the current request is from a guest (unauthenticated) user
  ///
  /// Returns true if the user is not authenticated, false if authenticated.
  bool get guest => _request?.isGuest ?? true;
}
