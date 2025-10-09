import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';

/// Mixin that enables query scopes on models with helper utilities
/// 
/// Query scopes allow you to define reusable query constraints
/// that can be chained in a fluent interface.
/// 
/// Example:
/// ```dart
/// class User extends KhademModel<User> with QueryScopes {
///   QueryBuilderInterface<User> scopeActive(QueryBuilderInterface<User> query) {
///     return query.where('active', '=', true);
///   }
///   
///   QueryBuilderInterface<User> scopeVerified(QueryBuilderInterface<User> query) {
///     return query.whereNotNull('email_verified_at');
///   }
///   
///   QueryBuilderInterface<User> scopeRole(
///     QueryBuilderInterface<User> query,
///     String role,
///   ) {
///     return query.where('role', '=', role);
///   }
///   
///   // Helper to chain multiple scopes
///   QueryBuilderInterface<User> activeVerifiedAdmins() {
///     return applyScopes([
///       (q) => scopeActive(q),
///       (q) => scopeVerified(q),
///       (q) => scopeRole(q, 'admin'),
///     ]);
///   }
/// }
/// 
/// // Usage:
/// final users = await User().activeVerifiedAdmins().get();
/// 
/// // Or manually chain:
/// final user = User();
/// final query = user.scopeActive(user.query);
/// final activeAdmins = await user.scopeRole(query, 'admin').get();
/// ```
/// 
/// ## Scope Naming Convention
/// 
/// - Scope method names must start with `scope` (e.g., `scopeActive`)
/// - Helper methods can combine multiple scopes
/// - All scopes receive QueryBuilderInterface and return QueryBuilderInterface
mixin QueryScopes<T> on KhademModel<T> {
  /// Apply multiple scope functions in sequence
  /// 
  /// This helper method allows you to chain multiple scopes programmatically
  /// without manually passing the query builder between them.
  /// 
  /// Example:
  /// ```dart
  /// class User extends KhademModel<User> with QueryScopes {
  ///   QueryBuilderInterface<User> activeAdmins() {
  ///     return applyScopes([
  ///       (q) => scopeActive(q),
  ///       (q) => scopeRole(q, 'admin'),
  ///     ]);
  ///   }
  /// }
  /// 
  /// // Usage:
  /// final users = await User().activeAdmins().get();
  /// ```
  QueryBuilderInterface<T> applyScopes<T>(
    List<QueryBuilderInterface<T> Function(QueryBuilderInterface<T>)> scopeFunctions,
  ) {
    var currentQuery = query as QueryBuilderInterface<T>;
    for (final scopeFunction in scopeFunctions) {
      currentQuery = scopeFunction(currentQuery);
    }
    return currentQuery;
  }

  /// Conditionally apply a scope based on a condition
  /// 
  /// This helper method allows you to apply scopes only when certain
  /// conditions are met, making your queries more dynamic.
  /// 
  /// Example:
  /// ```dart
  /// class User extends KhademModel<User> with QueryScopes {
  ///   QueryBuilderInterface<User> filteredUsers({String? role, bool? active}) {
  ///     var q = query;
  ///     q = when(active != null, q, (q) => scopeActive(q));
  ///     q = when(role != null, q, (q) => scopeRole(q, role!));
  ///     return q;
  ///   }
  /// }
  /// 
  /// // Usage:
  /// final users = await User().filteredUsers(role: 'admin', active: true).get();
  /// ```
  QueryBuilderInterface<T> when<T>(
    bool condition,
    QueryBuilderInterface<T> initialQuery,
    QueryBuilderInterface<T> Function(QueryBuilderInterface<T>) scopeFunction,
  ) {
    if (condition) {
      return scopeFunction(initialQuery);
    }
    return initialQuery;
  }

  /// Apply scope only when value is not null
  /// 
  /// Convenience method for conditional scopes based on null checks.
  /// 
  /// Example:
  /// ```dart
  /// QueryBuilderInterface<User> searchUsers(String? searchTerm, String? role) {
  ///   var q = query;
  ///   q = whenNotNull(searchTerm, q, (q, value) => scopeSearch(q, value));
  ///   q = whenNotNull(role, q, (q, value) => scopeRole(q, value));
  ///   return q;
  /// }
  /// ```
  QueryBuilderInterface<T> whenNotNull<T, V>(
    V? value,
    QueryBuilderInterface<T> initialQuery,
    QueryBuilderInterface<T> Function(QueryBuilderInterface<T>, V) scopeFunction,
  ) {
    if (value != null) {
      return scopeFunction(initialQuery, value);
    }
    return initialQuery;
  }

  /// Tap into query builder for debugging or side effects
  /// 
  /// Allows you to execute a function on the query builder without
  /// modifying it. Useful for logging or debugging.
  /// 
  /// Example:
  /// ```dart
  /// final users = await User()
  ///     .scopeActive(query)
  ///     .tap((q) => print('Current query: $q'))
  ///     .get();
  /// ```
  QueryBuilderInterface<T> tap<T>(
    QueryBuilderInterface<T> initialQuery,
    void Function(QueryBuilderInterface<T>) callback,
  ) {
    callback(initialQuery);
    return initialQuery;
  }

  /// Pipe query builder through multiple transformations
  /// 
  /// Similar to applyScopes but with a more functional style.
  /// 
  /// Example:
  /// ```dart
  /// final users = await User().pipe([
  ///   (q) => q.where('active', '=', true),
  ///   (q) => q.whereNotNull('email_verified_at'),
  ///   (q) => q.orderBy('created_at', direction: 'DESC'),
  /// ]).get();
  /// ```
  QueryBuilderInterface<T> pipe<T>(
    List<QueryBuilderInterface<T> Function(QueryBuilderInterface<T>)> transformations, [
    QueryBuilderInterface<T>? initialQuery,
  ]) {
    var currentQuery = initialQuery ?? query as QueryBuilderInterface<T>;
    for (final transformation in transformations) {
      currentQuery = transformation(currentQuery);
    }
    return currentQuery;
  }
}

