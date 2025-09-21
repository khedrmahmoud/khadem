import 'connection_interface.dart';
import 'schema_builder.dart';

/// Abstract factory for creating database-related components.
///
/// Used by the framework to provide connection and schema builders.
abstract class DatabaseFactoryInterface {
  /// Creates and returns a database connection instance from configuration.
  ///
  /// Example:
  /// ```dart
  /// final connection = factory.createConnection({
  ///   'driver': 'mysql',
  ///   'host': 'localhost',
  ///   'port': 3306,
  ///   ...
  /// });
  /// ```
  ConnectionInterface createConnection(Map<String, dynamic> config);

  /// Returns a schema builder for creating and modifying database structure.
  SchemaBuilder createSchemaBuilder();
}
