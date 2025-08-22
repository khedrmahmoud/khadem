/// Database contract that defines the required methods for database operations
abstract class DatabaseContract {
  /// Execute a query and return the results
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic> params = const [],
  ]);

  /// Execute a query and return the first result
  Future<Map<String, dynamic>?> queryFirst(
    String sql, [
    List<dynamic> params = const [],
  ]);

  /// Execute a query that doesn't return results
  Future<void> execute(
    String sql, [
    List<dynamic> params = const [],
  ]);

  /// Start a transaction
  Future<void> beginTransaction();

  /// Commit the current transaction
  Future<void> commit();

  /// Rollback the current transaction
  Future<void> rollback();

  /// Check if inside a transaction
  bool get inTransaction;

  /// Close the database connection
  Future<void> close();
}
