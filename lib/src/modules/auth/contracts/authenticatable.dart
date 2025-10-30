/// Interface for authenticatable entities (users)
///
/// This interface defines the contract that user models must implement
/// to be used with the authentication system. It provides a consistent
/// way to access user data across different authentication drivers.
///
/// Example implementation:
/// ```dart
/// class User implements Authenticatable {
///   final int id;
///   final String email;
///   final String password;
///   final bool isActive;
///
///   User({
///     required this.id,
///     required this.email,
///     required this.password,
///     this.isActive = true,
///   });
///
///   @override
///   dynamic getAuthIdentifier() => id;
///
///   @override
///   String getAuthIdentifierName() => 'id';
///
///   @override
///   String? getAuthPassword() => password;
///
///   @override
///   Map<String, dynamic> toAuthArray() => {
///     'id': id,
///     'email': email,
///     'is_active': isActive,
///   };
/// }
/// ```
abstract class Authenticatable {
  /// Gets the unique identifier for the user
  ///
  /// Returns the primary key value of the user
  dynamic getAuthIdentifier();

  /// Gets the name of the unique identifier column
  ///
  /// Returns the column name (e.g., 'id', 'uuid')
  String getAuthIdentifierName();

  /// Gets the password for the user
  ///
  /// Returns the hashed password or null if not set
  String? getAuthPassword();

  /// Converts the user to an array for authentication
  ///
  /// Returns a map of user data suitable for authentication responses
  Map<String, dynamic> toAuthArray();
}
