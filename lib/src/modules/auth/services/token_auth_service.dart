import 'dart:convert';
import 'dart:math';

import '../../../application/khadem.dart';
import '../../../support/helpers/hash_helper.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';

/// Token-based authentication service
///
/// This service provides simple token-based authentication without JWT complexity.
/// It generates secure random tokens for user sessions and stores them in the database.
/// Suitable for simpler applications or when JWT complexity is not needed.
///
/// Features:
/// - Secure random token generation
/// - Database-backed token storage
/// - Password hashing verification
/// - Simple token validation
/// - Automatic token cleanup
///
/// Configuration requirements:
/// ```yaml
/// auth:
///   providers:
///     users:
///       table: users
///       primary_key: id
///       fields: [email, username]
///   guards:
///     api:
///       driver: token
///       provider: users
/// ```
class TokenAuthService implements AuthDriver {
  /// The provider key for user data
  final String providerKey;

  /// Creates a token authentication service
  ///
  /// [providerKey] The key identifying the user provider configuration
  TokenAuthService({required this.providerKey});

  /// Attempts to authenticate a user with credentials
  ///
  /// [credentials] Map containing user credentials (email/username and password)
  /// Returns authentication result with user data and token
  /// Throws [AuthException] for invalid credentials or configuration errors
  @override
  Future<Map<String, dynamic>> attemptLogin(Map<String, dynamic> credentials) async {
    try {
      final provider = _getAuthProvider();
      final user = await _findUserByCredentials(credentials, provider);
      await _verifyPassword(credentials, user);
      final token = await _generateAndStoreToken(user, provider);

      return {
        'token': token,
        'user': user,
      };
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Login failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Gets the authentication provider configuration
  ///
  /// Returns the provider configuration for the current provider key
  /// Throws [AuthException] if provider is not configured
  Map<String, dynamic> _getAuthProvider() {
    final config = Khadem.config.section('auth');
    if (config == null) {
      throw AuthException('Authentication configuration not found');
    }

    final provider = config['providers']?[providerKey];
    if (provider == null) {
      throw AuthException('Authentication provider "$providerKey" not found');
    }

    return provider as Map<String, dynamic>;
  }

  /// Finds a user by their credentials
  ///
  /// [credentials] User login credentials
  /// [provider] Authentication provider configuration
  /// Returns the user record if found
  /// Throws [AuthException] if user is not found
  Future<Map<String, dynamic>> _findUserByCredentials(
    Map<String, dynamic> credentials,
    Map<String, dynamic> provider,
  ) async {
    final table = provider['table'] as String;
    final fields = provider['fields'] as List<dynamic>;

    final query = Khadem.db.table(table);
    bool hasValidField = false;

    for (final field in fields) {
      final fieldName = field as String;
      if (credentials.containsKey(fieldName) && credentials[fieldName] != null) {
        query.where(fieldName, '=', credentials[fieldName]);
        hasValidField = true;
      }
    }

    if (!hasValidField) {
      throw AuthException('No valid login field provided');
    }

    final user = await query.first();
    if (user == null) {
      throw AuthException('Invalid credentials');
    }

    return user as Map<String, dynamic>;
  }

  /// Verifies the user's password
  ///
  /// [credentials] User credentials containing password
  /// [user] User record from database
  /// Throws [AuthException] if password is invalid
  Future<void> _verifyPassword(Map<String, dynamic> credentials, Map<String, dynamic> user) async {
    final password = credentials['password'] as String?;
    if (password == null || password.isEmpty) {
      throw AuthException('Password is required');
    }

    final hashedPassword = user['password'] as String?;
    if (hashedPassword == null) {
      throw AuthException('User password not found');
    }

    final isValidPassword = await HashHelper.verify(password, hashedPassword);
    if (!isValidPassword) {
      throw AuthException('Invalid credentials');
    }
  }

  /// Generates and stores a secure token for the user
  ///
  /// [user] User data
  /// [provider] Provider configuration
  /// Returns the generated token
  Future<String> _generateAndStoreToken(Map<String, dynamic> user, Map<String, dynamic> provider) async {
    final primaryKey = provider['primary_key'] as String;
    final token = _generateSecureToken(id: user[primaryKey].toString());

    await Khadem.db.table('personal_access_tokens').insert({
      'token': token,
      'tokenable_id': user[primaryKey],
      'guard': providerKey,
      'created_at': DateTime.now().toIso8601String(),
    });

    return token;
  }

  /// Verifies a token and returns user data
  ///
  /// [token] The token to verify
  /// Returns the user data associated with the token
  /// Throws [AuthException] if token is invalid
  @override
  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final provider = _getAuthProvider();
      final tokenRecord = await _findTokenRecord(token);
      return await _findUserByToken(tokenRecord, provider);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Token verification failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Finds the token record in the database
  ///
  /// [token] The token to find
  /// Returns the token record
  /// Throws [AuthException] if token is not found
  Future<Map<String, dynamic>> _findTokenRecord(String token) async {
    final tokenRecord = await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', token)
        .first();

    if (tokenRecord == null) {
      throw AuthException('Invalid token');
    }

    return tokenRecord as Map<String, dynamic>;
  }

  /// Finds a user by token record
  ///
  /// [tokenRecord] The token record from database
  /// [provider] Provider configuration
  /// Returns the user record
  /// Throws [AuthException] if user is not found
  Future<Map<String, dynamic>> _findUserByToken(
    Map<String, dynamic> tokenRecord,
    Map<String, dynamic> provider,
  ) async {
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;
    final userId = tokenRecord['tokenable_id'];

    final user = await Khadem.db.table(table).where(primaryKey, '=', userId).first();

    if (user == null) {
      throw AuthException('User not found');
    }

    return user as Map<String, dynamic>;
  }

  /// Logs out a user by removing their token
  ///
  /// [token] The token to invalidate
  @override
  Future<void> logout(String token) async {
    try {
      await Khadem.db
          .table('personal_access_tokens')
          .where('token', '=', token)
          .delete();
    } catch (e) {
      throw AuthException(
        'Logout failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Generates a secure random token
  ///
  /// [length] The length of the token to generate
  /// Returns a base64 URL-encoded secure random token
  String _generateSecureToken({int length = 64, String id = ''}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    final tokenPart = base64UrlEncode(bytes).substring(0, length);
    return id.isEmpty ? tokenPart : "$id|$tokenPart";
  }
}
