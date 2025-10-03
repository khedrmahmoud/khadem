import '../contracts/token_service.dart';
import '../repositories/database_auth_repository.dart';

/// Database implementation of TokenService
///
/// This service provides concrete token management operations
/// using the existing DatabaseAuthRepository.
class DatabaseTokenService implements TokenService {
  final DatabaseAuthRepository _repository;

  DatabaseTokenService({DatabaseAuthRepository? repository})
      : _repository = repository ?? DatabaseAuthRepository();

  @override
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData) async {
    await _repository.storeToken(tokenData);
    return tokenData;
  }

  @override
  Future<Map<String, dynamic>?> findToken(String token) async {
    return _repository.findToken(token);
  }

  @override
  Future<List<Map<String, dynamic>>> findTokensByUser(
    dynamic userId, [
    String? guard,
  ]) async {
    return _repository.findTokensByUser(userId, guard);
  }

  @override
  Future<int> deleteToken(String token) async {
    return _repository.deleteToken(token);
  }

  @override
  Future<int> deleteUserTokens(dynamic userId, [String? guard]) async {
    return _repository.deleteUserTokens(userId, guard);
  }

  @override
  Future<int> cleanupExpiredTokens() async {
    return _repository.cleanupExpiredTokens();
  }

  @override
  Future<Map<String, dynamic>> blacklistToken(Map<String, dynamic> tokenData) async {
    await _repository.storeToken(tokenData);
    return tokenData;
  }

  @override
  Future<bool> isTokenBlacklisted(String token) async {
    final tokenRecord = await _repository.findToken(token);
    return tokenRecord != null && tokenRecord['type'] == 'blacklist';
  }

  @override
  Future<List<Map<String, dynamic>>> findTokensBySession(
    String sessionId, [
    String? guard,
    String? type,
  ]) async {
    // Use database-level prefix search for better performance
    final sessionPrefix = '$sessionId::';
    return _repository.findTokensByPrefix(
      sessionPrefix,
      type: type,
      guard: guard,
    );
  }

  @override
  Future<int> invalidateSession(String sessionId, [String? guard]) async {
    // Find all tokens for this session
    final sessionTokens = await findTokensBySession(sessionId, guard);
    
    int invalidatedCount = 0;
    for (final tokenData in sessionTokens) {
      final token = tokenData['token'] as String?;
      if (token != null) {
        invalidatedCount += await deleteToken(token);
      }
    }
    
    return invalidatedCount;
  }
}