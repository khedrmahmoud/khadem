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

  // ---------------------------- OR WHERE Variants ----------------------------

  /// OR WHERE column IN (values)
  QueryBuilderInterface<T> orWhereIn(String column, List<dynamic> values);

  /// OR WHERE column NOT IN (values)
  QueryBuilderInterface<T> orWhereNotIn(String column, List<dynamic> values);

  /// OR WHERE column IS NULL
  QueryBuilderInterface<T> orWhereNull(String column);

  /// OR WHERE column IS NOT NULL
  QueryBuilderInterface<T> orWhereNotNull(String column);

  /// OR WHERE column BETWEEN start AND end
  QueryBuilderInterface<T> orWhereBetween(
    String column,
    dynamic start,
    dynamic end,
  );

  /// OR WHERE column NOT BETWEEN start AND end
  QueryBuilderInterface<T> orWhereNotBetween(
    String column,
    dynamic start,
    dynamic end,
  );

  /// OR WHERE column LIKE pattern
  QueryBuilderInterface<T> orWhereLike(String column, String pattern);

  /// OR WHERE column NOT LIKE pattern
  QueryBuilderInterface<T> orWhereNotLike(String column, String pattern);

  /// OR WHERE DATE(column) = date
  QueryBuilderInterface<T> orWhereDate(String column, String date);

  /// OR WHERE TIME(column) = time
  QueryBuilderInterface<T> orWhereTime(String column, String time);

  /// OR WHERE YEAR(column) = year
  QueryBuilderInterface<T> orWhereYear(String column, int year);

  /// OR WHERE MONTH(column) = month
  QueryBuilderInterface<T> orWhereMonth(String column, int month);

  /// OR WHERE DAY(column) = day
  QueryBuilderInterface<T> orWhereDay(String column, int day);

  /// OR WHERE column1 operator column2
  QueryBuilderInterface<T> orWhereColumn(
    String column1,
    String operator,
    String column2,
  );

  /// OR WHERE JSON_CONTAINS
  QueryBuilderInterface<T> orWhereJsonContains(
    String column,
    dynamic value, [
    String? path,
  ]);

  // ---------------------------- Relationship Queries (whereHas) ----------------------------

  /// Query for existence of a relationship with optional constraints
  /// Equivalent to Laravel's whereHas()
  ///
  /// Example:
  /// ```dart
  /// Post.query().whereHas('comments', (q) => q.where('approved', '=', true))
  /// ```
  QueryBuilderInterface<T> whereHas(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator = '>=',
    int count = 1,
  ]);

  /// OR version of whereHas
  QueryBuilderInterface<T> orWhereHas(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator = '>=',
    int count = 1,
  ]);

  /// Query for absence of a relationship
  QueryBuilderInterface<T> whereDoesntHave(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
  ]);

  /// OR version of whereDoesntHave
  QueryBuilderInterface<T> orWhereDoesntHave(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
  ]);

  /// Query with relationship count
  QueryBuilderInterface<T> has(String relation, [String operator = '>=', int count = 1]);

  /// Query without any of the relationship
  QueryBuilderInterface<T> doesntHave(String relation);

  // ---------------------------- Advanced Column Comparisons ----------------------------

  /// WHERE column value is BETWEEN two other columns' values
  QueryBuilderInterface<T> whereBetweenColumns(
    String column,
    String startColumn,
    String endColumn,
  );

  /// WHERE column value is NOT BETWEEN two other columns' values
  QueryBuilderInterface<T> whereNotBetweenColumns(
    String column,
    String startColumn,
    String endColumn,
  );

  // ---------------------------- Advanced Date Comparisons ----------------------------

  /// WHERE column is in the past
  QueryBuilderInterface<T> wherePast(String column);

  /// WHERE column is in the future
  QueryBuilderInterface<T> whereFuture(String column);

  /// WHERE column date is today
  QueryBuilderInterface<T> whereToday(String column);

  /// WHERE column date is before today
  QueryBuilderInterface<T> whereBeforeToday(String column);

  /// WHERE column date is after today
  QueryBuilderInterface<T> whereAfterToday(String column);

  // ---------------------------- Subquery Methods ----------------------------

  /// Set a subquery as the FROM clause
  QueryBuilderInterface<T> fromSub(
    QueryBuilderInterface<dynamic> query,
    String alias,
  );

  /// Set raw SQL as the FROM clause
  QueryBuilderInterface<T> fromRaw(String sql, [List<dynamic> bindings = const []]);

  /// Add a subquery to the SELECT clause
  QueryBuilderInterface<T> selectSub(
    QueryBuilderInterface<dynamic> query,
    String alias,
  );

  // ---------------------------- Logical Grouping ----------------------------

  /// Add a nested WHERE clause group
  QueryBuilderInterface<T> whereNested(
    void Function(QueryBuilderInterface<T> query) callback,
  );

  /// Add a nested OR WHERE clause group
  QueryBuilderInterface<T> orWhereNested(
    void Function(QueryBuilderInterface<T> query) callback,
  );

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

  /// Excludes specific relations from the model's defaultRelations.
  ///
  /// This is useful when you want to load most default relations
  /// but skip specific ones for performance.
  ///
  /// ```dart
  /// // Model has defaultRelations: ['posts', 'profile', 'roles']
  /// final users = await UserModel.q<UserModel>()
  ///   .without(['posts', 'roles'])  // Only loads 'profile'
  ///   .get();
  /// ```
  QueryBuilderInterface<T> without(List<String> relations);

  // ---------------------------- Relationship Aggregates ----------------------------

  /// Load relationship counts without loading the full relationships.
  ///
  /// Adds a `{relation}Count` attribute to each model with the count.
  ///
  /// ```dart
  /// final users = await User.query()
  ///   .withCount(['posts', 'comments'])
  ///   .get();
  ///
  /// print(users.first.postsCount); // 25
  /// print(users.first.commentsCount); // 150
  /// ```
  ///
  /// You can also apply constraints to the count:
  /// ```dart
  /// final users = await User.query()
  ///   .withCount({
  ///     'posts': (q) => q.where('published', '=', true),
  ///     'comments': (q) => q.where('approved', '=', true),
  ///   })
  ///   .get();
  /// ```
  QueryBuilderInterface<T> withCount(dynamic relations);

  /// Load relationship sum aggregates without loading the full relationships.
  ///
  /// Adds a `{relation}{Column}Sum` attribute to each model.
  ///
  /// ```dart
  /// final users = await User.query()
  ///   .withSum('orders', 'amount')
  ///   .get();
  ///
  /// print(users.first.ordersAmountSum); // 1500.50
  /// ```
  QueryBuilderInterface<T> withSum(String relation, String column);

  /// Load relationship average aggregates without loading the full relationships.
  ///
  /// Adds a `{relation}{Column}Avg` attribute to each model.
  ///
  /// ```dart
  /// final users = await User.query()
  ///   .withAvg('orders', 'rating')
  ///   .get();
  ///
  /// print(users.first.ordersRatingAvg); // 4.5
  /// ```
  QueryBuilderInterface<T> withAvg(String relation, String column);

  /// Load relationship maximum aggregates without loading the full relationships.
  ///
  /// Adds a `{relation}{Column}Max` attribute to each model.
  ///
  /// ```dart
  /// final users = await User.query()
  ///   .withMax('posts', 'views')
  ///   .get();
  ///
  /// print(users.first.postsViewsMax); // 50000
  /// ```
  QueryBuilderInterface<T> withMax(String relation, String column);

  /// Load relationship minimum aggregates without loading the full relationships.
  ///
  /// Adds a `{relation}{Column}Min` attribute to each model.
  ///
  /// ```dart
  /// final users = await User.query()
  ///   .withMin('posts', 'views')
  ///   .get();
  ///
  /// print(users.first.postsViewsMin); // 10
  /// ```
  QueryBuilderInterface<T> withMin(String relation, String column);

  /// Replaces the model's defaultRelations with the specified relations.
  ///
  /// Use this when you want to load completely different relations
  /// instead of the defaults.
  ///
  /// ```dart
  /// // Model has defaultRelations: ['posts', 'profile']
  /// final users = await UserModel.q<UserModel>()
  ///   .withOnly(['followers', 'following'])  // Ignores defaults
  ///   .get();
  /// ```
  QueryBuilderInterface<T> withOnly(List<dynamic> relations);

  /// Clones the current query builder instance.
  QueryBuilderInterface<T> clone();
}
