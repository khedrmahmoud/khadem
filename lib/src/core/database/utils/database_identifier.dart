import '../../../support/exceptions/database_exception.dart';

/// Utility helpers for validating and quoting SQL database identifiers.
class DatabaseIdentifier {
  /// Validates a MySQL database identifier and returns the trimmed value.
  static String validateMySqlDatabaseName(String dbName) {
    final normalized = dbName.trim();

    if (normalized.isEmpty || normalized.length > 64) {
      throw DatabaseException('Invalid database name: must be 1-64 characters');
    }

    final validPattern = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');
    if (!validPattern.hasMatch(normalized)) {
      throw DatabaseException(
        'Invalid database name: must contain only alphanumeric characters, underscores, and dollar signs, and cannot start with a digit',
      );
    }

    if (normalized.contains('`')) {
      throw DatabaseException(
        'Invalid database name: cannot contain backtick characters',
      );
    }

    return normalized;
  }

  /// Safely quotes a MySQL identifier after validation.
  static String quoteMySqlIdentifier(String identifier) {
    return '`${identifier.replaceAll('`', '``')}`';
  }
}
