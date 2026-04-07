import 'package:khadem/src/core/database/utils/database_identifier.dart';
import 'package:khadem/src/support/exceptions/database_exception.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseIdentifier', () {
    test('validateMySqlDatabaseName accepts valid names', () {
      expect(
        DatabaseIdentifier.validateMySqlDatabaseName('khadem_main'),
        'khadem_main',
      );
      expect(
        DatabaseIdentifier.validateMySqlDatabaseName('db\$tenant1'),
        'db\$tenant1',
      );
    });

    test('validateMySqlDatabaseName rejects unsafe names', () {
      expect(
        () => DatabaseIdentifier.validateMySqlDatabaseName('db-name'),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        () => DatabaseIdentifier.validateMySqlDatabaseName('1database'),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        () => DatabaseIdentifier.validateMySqlDatabaseName(
          'prod`; DROP DATABASE app; --',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('quoteMySqlIdentifier quotes identifiers safely', () {
      expect(
        DatabaseIdentifier.quoteMySqlIdentifier('khadem_main'),
        '`khadem_main`',
      );
      expect(
        DatabaseIdentifier.quoteMySqlIdentifier('name`withtick'),
        '`name``withtick`',
      );
    });
  });
}
