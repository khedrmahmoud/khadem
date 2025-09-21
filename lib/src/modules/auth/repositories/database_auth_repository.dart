import '../../../application/khadem.dart';
import '../contracts/auth_repository.dart';

/// Database implementation of AuthRepository
///
/// This class implements the AuthRepository interface using the Khadem
/// database layer. It provides concrete implementations for all
/// authentication data access operations.
class DatabaseAuthRepository implements AuthRepository {
  @override
  Future<Map<String, dynamic>?> findUserByCredentials(
    Map<String, dynamic> credentials,
    List<String> fields,
    String table,
  ) async {
    final query = Khadem.db.table(table);
    bool hasValidField = false;

    for (final field in fields) {
      if (credentials.containsKey(field) && credentials[field] != null) {
        query.where(field, '=', credentials[field]);
        hasValidField = true;
      }
    }

    if (!hasValidField) {
      return null;
    }

    final result = await query.first();
    return result as Map<String, dynamic>?;
  }

  @override
  Future<Map<String, dynamic>?> findUserById(
    dynamic id,
    String table,
    String primaryKey,
  ) async {
    final result = await Khadem.db
        .table(table)
        .where(primaryKey, '=', id)
        .first();

    return result as Map<String, dynamic>?;
  }

  @override
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData) async {
    await Khadem.db.table('personal_access_tokens').insert(tokenData);
    return tokenData;
  }

  @override
  Future<Map<String, dynamic>?> findToken(String token) async {
    final result = await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', token)
        .first();

    return result as Map<String, dynamic>?;
  }

  @override
  Future<int> deleteToken(String token) async {
    await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', token)
        .delete();
    return 1; // Assuming successful deletion
  }

  @override
  Future<int> deleteUserTokens(dynamic userId, [String? guard]) async {
    final query = Khadem.db
        .table('personal_access_tokens')
        .where('tokenable_id', '=', userId);

    if (guard != null) {
      query.where('guard', '=', guard);
    }

    await query.delete();
    return 1; // Assuming successful deletion
  }

  @override
  Future<int> cleanupExpiredTokens() async {
    await Khadem.db
        .table('personal_access_tokens')
        .where('expires_at', '<', DateTime.now().toIso8601String())
        .delete();
    return 1; // Assuming successful deletion
  }
}
