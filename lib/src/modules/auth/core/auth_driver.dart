abstract class AuthDriver {
  Future<Map<String, dynamic>> attemptLogin(Map<String, dynamic> credentials);
  Future<Map<String, dynamic>> verifyToken(String token);
  Future<void> logout(String token);
}
