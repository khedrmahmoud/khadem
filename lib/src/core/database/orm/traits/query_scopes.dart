/// Mixin that enables query scopes on models
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
/// }
/// 
/// // Usage:
/// final users = await User.query()
///     .active()
///     .verified()
///     .role('admin')
///     .get();
/// ```
/// 
/// ## How It Works
/// 
/// 1. Define methods prefixed with `scope` on your model
/// 2. Each scope method receives the query builder and returns the modified query builder
/// 3. Scopes can accept additional parameters
/// 4. Chain scopes together using fluent syntax
/// 
/// ## Scope Naming Convention
/// 
/// - Scope method names must start with `scope`
/// - The actual query method will be the lowercase version without `scope`
/// - Example: `scopeActive` becomes `.active()`
/// - Example: `scopeRole` becomes `.role(param)`
mixin QueryScopes {}

