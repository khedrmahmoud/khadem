import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/concerns/interacts_with_database.dart';

/// Mixin that enables query scopes on models with helper utilities
mixin QueryScopes<T> on InteractsWithDatabase<T> {
  /// Apply multiple scope functions in sequence
  QueryBuilderInterface<T> applyScopes(
    List<QueryBuilderInterface<T> Function(QueryBuilderInterface<T>)>
    scopeFunctions,
  ) {
    var currentQuery = query;
    for (final scopeFunction in scopeFunctions) {
      currentQuery = scopeFunction(currentQuery);
    }
    return currentQuery;
  }

  /// Conditionally apply a scope based on a condition
  QueryBuilderInterface<T> when(
    bool condition,
    QueryBuilderInterface<T> currentQuery,
    QueryBuilderInterface<T> Function(QueryBuilderInterface<T>) scopeFunction,
  ) {
    if (condition) {
      return scopeFunction(currentQuery);
    }
    return currentQuery;
  }

  /// Apply a scope unless a condition is met
  QueryBuilderInterface<T> unless(
    bool condition,
    QueryBuilderInterface<T> currentQuery,
    QueryBuilderInterface<T> Function(QueryBuilderInterface<T>) scopeFunction,
  ) {
    if (!condition) {
      return scopeFunction(currentQuery);
    }
    return currentQuery;
  }
}
