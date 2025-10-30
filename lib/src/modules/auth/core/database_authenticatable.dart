import '../contracts/authenticatable.dart';

/// Database authenticatable implementation
///
/// This class provides a standardized implementation of Authenticatable
/// that uses provider configuration to determine field mappings.
/// It eliminates code duplication across drivers and guards.
class DatabaseAuthenticatable implements Authenticatable {
  /// The raw user data from database
  final Map<String, dynamic> _data;

  /// The primary key field name from provider config
  final String _primaryKey;

  /// The password field name (defaults to 'password')
  final String _passwordField;

  /// Creates a database authenticatable instance
  DatabaseAuthenticatable(
    this._data, {
    required String primaryKey,
    String passwordField = 'password',
  })  : _primaryKey = primaryKey,
        _passwordField = passwordField;

  /// Factory constructor that creates instance from provider config
  factory DatabaseAuthenticatable.fromProviderConfig(
    Map<String, dynamic> userData,
    Map<String, dynamic> providerConfig,
  ) {
    final primaryKey = providerConfig['primary_key'] as String? ?? 'id';
    final passwordField =
        providerConfig['password_field'] as String? ?? 'password';

    return DatabaseAuthenticatable(
      userData,
      primaryKey: primaryKey,
      passwordField: passwordField,
    );
  }

  @override
  dynamic getAuthIdentifier() => _data[_primaryKey];

  @override
  String getAuthIdentifierName() => _primaryKey;

  @override
  String? getAuthPassword() => _data[_passwordField];

  @override
  Map<String, dynamic> toAuthArray() => Map<String, dynamic>.from(_data);
}
