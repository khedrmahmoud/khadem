import 'package:khadem/khadem.dart' show MigrationFile;

class CreatePersonalAccessTokenTable extends MigrationFile {
  @override
  Future<void> up(schema) async {
    schema.create('personal_access_tokens', (table) {
      // Define columns
      table.id();
      table.foreignId('tokenable_id');
      table.string("token").unique();
      table.string('type', length: 50);
      table.string('guard', length: 50);
      table.date('created_at').nullable();
      table.date('expires_at').nullable();
    });
  }

  @override
  Future<void> down(schema) async {
    schema.drop('personal_access_tokens');
  }
}
