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
    final result =
        await Khadem.db.table(table).where(primaryKey, '=', id).first();

    return result as Map<String, dynamic>?;
  }

  @override
  Future<Map<String, dynamic>> storeToken(
    Map<String, dynamic> tokenData,
  ) async {
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
  Future<int> deleteUserTokens(dynamic userId,
      {String? guard, Map<String, dynamic>? filter,}) async {
    final query = Khadem.db
        .table('personal_access_tokens')
        .where('tokenable_id', '=', userId);

    if (guard != null) {
      query.where('guard', '=', guard);
    }
    if (filter != null) {
      filter.forEach((key, value) {
        if (value is List) {
          query.whereRaw('$key IN (${value.map((v) => "'$v'").join(", ")})');
        } else {
          query.where(key, '=', value);
        }
      });
    }

    await query.delete();
    return 1; // Assuming successful deletion
  }

  @override
  Future<List<Map<String, dynamic>>> findTokensByUser(
    dynamic userId, [
    String? guard,
  ]) async {
    final query = Khadem.db
        .table('personal_access_tokens')
        .where('tokenable_id', '=', userId);

    if (guard != null) {
      query.where('guard', '=', guard);
    }

    final results = await query.get();
    return results.map((row) => row as Map<String, dynamic>).toList();
  }

  /// Find tokens by their token string prefix
  ///
  /// This is used for finding session-correlated tokens efficiently
  Future<List<Map<String, dynamic>>> findTokensByPrefix(
    String prefix, {
    String? type,
    String? guard,
  }) async {
    final query = Khadem.db.table('personal_access_tokens').whereRaw(
        'token LIKE ?', ['$prefix%'],); // Use SQL LIKE for prefix search

    if (type != null) {
      query.where('type', '=', type);
    }
    if (guard != null) {
      query.where('guard', '=', guard);
    }

    final results = await query.get();
    return results.map((row) => row as Map<String, dynamic>).toList();
  }

  @override
  Future<int> cleanupExpiredTokens() async {
    await Khadem.db
        .table('personal_access_tokens')
        .where('expires_at', '<', DateTime.now().toIso8601String())
        .delete();
    return 1; // Assuming successful deletion
  }

  /// Finds tokens by filter criteria
  ///
  /// [filters] A map of column names and values to filter by
  Future<List<Map<String, dynamic>>> findTokensByFilter(
      Map<String, dynamic> filters,) async {
    final query = Khadem.db.table('personal_access_tokens');

    filters.forEach((key, value) {
      query.where(key, '=', value);
    });

    final results = await query.get();
    return results.map((row) => row as Map<String, dynamic>).toList();
  }
}
