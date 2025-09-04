/// Password verification interface
///
/// This interface defines the contract for password verification
/// in the authentication system. It allows for different hashing
/// algorithms while maintaining consistency.
abstract class PasswordVerifier {
  /// Verifies a password against its hash
  ///
  /// [password] The plain text password
  /// [hash] The hashed password to verify against
  /// Returns true if password matches the hash
  Future<bool> verify(String password, String hash);

  /// Hashes a password
  ///
  /// [password] The plain text password to hash
  /// Returns the hashed password
  Future<String> hash(String password);

  /// Checks if a hash needs rehashing
  ///
  /// [hash] The hash to check
  /// Returns true if rehashing is needed
  bool needsRehash(String hash);
}
