import 'dart:async';

import 'package:khadem/src/core/database/model_base/khadem_model.dart';

import '../../core/database/orm/paginated_result.dart';

/// A generic interface for building SQL-like queries dynamically.
/// Supports both raw Map responses or strongly-typed KhademModel instances.
///
/// Example usage:
/// ```dart
/// final users = await UserModel.q<UserModel>()
///   .where('active', '=', true)
///   .orderBy('created_at', direction: 'DESC')
///   .limit(10)
///   .get();
/// ```
abstract class QueryBuilderInterface<T> {
  QueryBuilderInterface() {
    _validateGenericType();
  }

  /// Ensures the type is either Map&lt;String, dynamic&gt; or a BaseModel subclass.
  void _validateGenericType() {
    if (!(T is Map || T is Map<String, dynamic> || T is KhademModel)) {
      throw UnsupportedError(
        'QueryBuilderInterface only supports Map<String, dynamic> or KhademModel subclasses',
      );
    }
  }
  // ---------------------------- Basic Clauses ----------------------------

  /// Selects specific columns (defaults to *).
  QueryBuilderInterface<T> select(List<String> columns);

  /// Adds a basic WHERE clause.
  QueryBuilderInterface<T> where(String column, String operator, dynamic value);

  /// Adds a raw SQL WHERE clause.
  QueryBuilderInterface<T> whereRaw(
    String sql, [
    List<dynamic> bindings = const [],
  ]);

  /// Adds an OR WHERE clause.
  QueryBuilderInterface<T> orWhere(
    String column,
    String operator,
    dynamic value,
  );

  // ---------------------------- Advanced WHERE Clauses ----------------------------

  /// WHERE column IN (values)
  QueryBuilderInterface<T> whereIn(String column, List<dynamic> values);

  /// WHERE column NOT IN (values)
  QueryBuilderInterface<T> whereNotIn(String column, List<dynamic> values);

  /// WHERE column IS NULL
  QueryBuilderInterface<T> whereNull(String column);

  /// WHERE column IS NOT NULL
  QueryBuilderInterface<T> whereNotNull(String column);

  /// WHERE column BETWEEN start AND end
  QueryBuilderInterface<T> whereBetween(
    String column,
    dynamic start,
    dynamic end,
  );

  /// WHERE column NOT BETWEEN start AND end
  QueryBuilderInterface<T> whereNotBetween(
    String column,
    dynamic start,
    dynamic end,
  );

  /// WHERE column LIKE pattern
  QueryBuilderInterface<T> whereLike(String column, String pattern);

  /// WHERE column NOT LIKE pattern
  QueryBuilderInterface<T> whereNotLike(String column, String pattern);

  /// WHERE DATE(column) = date
  QueryBuilderInterface<T> whereDate(String column, String date);

  /// WHERE TIME(column) = time
  QueryBuilderInterface<T> whereTime(String column, String time);

  /// WHERE YEAR(column) = year
  QueryBuilderInterface<T> whereYear(String column, int year);

  /// WHERE MONTH(column) = month
  QueryBuilderInterface<T> whereMonth(String column, int month);

  /// WHERE DAY(column) = day
  QueryBuilderInterface<T> whereDay(String column, int day);

  /// WHERE column1 operator column2 (compare two columns)
  QueryBuilderInterface<T> whereColumn(
    String column1,
    String operator,
    String column2,
  );

  // ---------------------------- JSON Operations ----------------------------

  /// WHERE JSON_CONTAINS(column, value, path)
  QueryBuilderInterface<T> whereJsonContains(
    String column,
    dynamic value, [
    String? path,
  ]);

  /// WHERE NOT JSON_CONTAINS(column, value, path)
  QueryBuilderInterface<T> whereJsonDoesntContain(
    String column,
    dynamic value, [
    String? path,
  ]);

  /// WHERE JSON_LENGTH(column, path) operator value
  QueryBuilderInterface<T> whereJsonLength(
    String column,
    String operator,
    int length, [
    String? path,
  ]);

  /// WHERE JSON_CONTAINS_PATH(column, 'one', path)
  QueryBuilderInterface<T> whereJsonContainsKey(String column, String path);

  // ---------------------------- Advanced Query Helpers ----------------------------

  /// Matches ANY of the columns with the given operator and value
  QueryBuilderInterface<T> whereAny(
    List<String> columns,
    String operator,
    dynamic value,
  );

  /// Matches ALL of the conditions
  QueryBuilderInterface<T> whereAll(Map<String, dynamic> conditions);

  /// Matches NONE of the conditions
  QueryBuilderInterface<T> whereNone(Map<String, dynamic> conditions);

  /// Shorthand for orderBy(column, 'DESC')
  QueryBuilderInterface<T> latest([String column = 'created_at']);

  /// Shorthand for orderBy(column, 'ASC')
  QueryBuilderInterface<T> oldest([String column = 'created_at']);

  /// ORDER BY RAND()
  QueryBuilderInterface<T> inRandomOrder();

  /// SELECT DISTINCT
  QueryBuilderInterface<T> distinct();

  /// Add more columns to select
  QueryBuilderInterface<T> addSelect(List<String> columns);

  // ---------------------------- JOIN Operations ----------------------------

  /// INNER JOIN
  QueryBuilderInterface<T> join(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  );

  /// LEFT JOIN
  QueryBuilderInterface<T> leftJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  );

  /// RIGHT JOIN
  QueryBuilderInterface<T> rightJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  );

  /// CROSS JOIN
  QueryBuilderInterface<T> crossJoin(String table);

  // ---------------------------- Bulk Operations ----------------------------

  /// Insert multiple rows at once
  Future<List<int>> insertMany(List<Map<String, dynamic>> rows);

  /// Insert or update (UPSERT) - MySQL: INSERT ... ON DUPLICATE KEY UPDATE
  Future<int> upsert(
    List<Map<String, dynamic>> rows, {
    required List<String> uniqueBy,
    List<String>? update,
  });

  /// Increment a column value
  Future<int> increment(String column, [int amount = 1]);

  /// Decrement a column value
  Future<int> decrement(String column, [int amount = 1]);

  /// Increment multiple columns
  Future<void> incrementEach(Map<String, int> columns);

  /// Process results in chunks
  Future<void> chunk(
    int size,
    Future<void> Function(List<T> items) callback,
  );

  /// Process results in chunks by ID (more efficient for large datasets)
  Future<void> chunkById(
    int size,
    Future<void> Function(List<T> items) callback, {
    String column = 'id',
    String? alias,
  });

  /// Lazy load results as a stream (alternative to asStream for chunking)
  Stream<T> lazy([int chunkSize = 100]);

  // ---------------------------- Advanced Pagination & Locking ----------------------------

  /// Simple pagination without total count (faster)
  Future<Map<String, dynamic>> simplePaginate({
    int perPage = 15,
    int page = 1,
  });

  /// Cursor-based pagination for efficient large dataset navigation
  Future<Map<String, dynamic>> cursorPaginate({
    int perPage = 15,
    String? cursor,
    String column = 'id',
  });

  /// Add shared lock (FOR SHARE) - prevents updates until transaction completes
  QueryBuilderInterface<T> sharedLock();

  /// Add exclusive lock (FOR UPDATE) - prevents reads and updates
  QueryBuilderInterface<T> lockForUpdate();

  // ---------------------------- Union & Subqueries ----------------------------

  /// UNION - combines results from two queries (removes duplicates)
  QueryBuilderInterface<T> union(QueryBuilderInterface<T> query);

  /// UNION ALL - combines results from two queries (keeps duplicates)
  QueryBuilderInterface<T> unionAll(QueryBuilderInterface<T> query);

  /// WHERE column IN (subquery)
  QueryBuilderInterface<T> whereInSubquery(
    String column,
    String Function(QueryBuilderInterface<dynamic> query) callback,
  );

  /// WHERE EXISTS (subquery)
  QueryBuilderInterface<T> whereExists(
    String Function(QueryBuilderInterface<dynamic> query) callback,
  );

  /// WHERE NOT EXISTS (subquery)
  QueryBuilderInterface<T> whereNotExists(
    String Function(QueryBuilderInterface<dynamic> query) callback,
  );

  // ---------------------------- Full-Text Search ----------------------------

  /// Full-text search using MySQL MATCH AGAINST
  QueryBuilderInterface<T> whereFullText(
    List<String> columns,
    String searchTerm, {
    String mode = 'natural', // natural, boolean, query_expansion
  });

  // ---------------------------- Basic Clauses ----------------------------

  /// Limits the number of results.
  QueryBuilderInterface<T> limit(int number);

  /// Offsets the results (useful with pagination).
  QueryBuilderInterface<T> offset(int number);

  /// Adds ORDER BY clause.
  QueryBuilderInterface<T> orderBy(String column, {String direction = 'ASC'});

  /// Adds GROUP BY clause.
  QueryBuilderInterface<T> groupBy(String column);

  /// Adds HAVING clause.
  QueryBuilderInterface<T> having(
    String column,
    String operator,
    dynamic value,
  );

  // ---------------------------- Result Execution ----------------------------

  /// Executes and returns all matching rows.
  Future<List<T>> get();

  /// Returns the first row only.
  Future<T?> first();

  /// Returns a stream of results for memory-efficient processing.
  Stream<T> asStream();

  /// Returns a paginated result.
  Future<PaginatedResult<T>> paginate({int? perPage = 10, int? page = 1});

  /// Inserts a new row.
  Future<int> insert(Map<String, dynamic> data);

  /// Updates rows matching where conditions.
  Future<void> update(Map<String, dynamic> data);

  /// Deletes rows matching where conditions.
  Future<void> delete();

  // ---------------------------- Extras ----------------------------

  /// Returns true if any row matches the query.
  Future<bool> exists();

  /// Returns total count of matched rows.
  Future<int> count();

  /// Returns a single column values as list.
  Future<List<dynamic>> pluck(String column);

  /// Returns the sum of a numeric column.
  Future<num> sum(String column);

  /// Returns the average of a numeric column.
  Future<num> avg(String column);

  /// Returns the maximum value of a numeric column.
  Future<int> max(String column);

  /// Returns the minimum value of a numeric column.
  Future<int> min(String column);

  /// Returns the raw SQL string.
  String toSql();

  /// Conditionally adds clauses based on [condition].
  QueryBuilderInterface<T> when(
    bool condition,
    QueryBuilderInterface<T> Function(QueryBuilderInterface<T> q) builder,
  );

  /// Eagerly loads relations for the query.
  ///
  /// ```dart
  /// final users = await UserModel.q<UserModel>()
  ///   .withRelations(['posts'])
  ///   .get();
  /// ```
  QueryBuilderInterface<T> withRelations(List<dynamic> relations);

  /// Clones the current query builder instance.
  QueryBuilderInterface<T> clone();
}
