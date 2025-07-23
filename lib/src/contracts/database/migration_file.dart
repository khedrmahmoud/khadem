import 'schema_builder.dart';

/// Contract representing a database migration file.
///
/// Implement this class to define schema changes for your database.
///
/// Example:
/// ```dart
/// class CreateUsersTable extends MigrationFile {
///   @override
///   Future<void> up(SchemaBuilder builder) async {
///     builder.create('users', (table) {
///       table.id();
///       table.string('name');
///     });
///   }
///
///   @override
///   Future<void> down(SchemaBuilder builder) async {
///     builder.drop('users');
///   }
/// }
/// ```
abstract class MigrationFile {
  MigrationFile();

  /// Defines the schema operations to apply.
  Future<void> up(SchemaBuilder builder);

  /// Defines how to reverse the schema operations.
  Future<void> down(SchemaBuilder builder);

  /// Optional name for this migration (usually class name).
  String get name => runtimeType.toString();
}
