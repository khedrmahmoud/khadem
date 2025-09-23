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
