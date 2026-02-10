import 'package:khadem/contracts.dart' show MigrationFile, SchemaBuilder;

class CreatePersonalAccessTokenTable extends MigrationFile {
  @override
  Future<void> up(SchemaBuilder builder) async {
    builder.create('personal_access_tokens', (table) {
      table.id();
      table.foreignId('tokenable_id');
      table.text("token");
      table.string('type', length: 50);
      table.string('guard', length: 50);
      table.timestamp('created_at').nullable();
      table.timestamp('expires_at').nullable();
    });
  }

  @override
  Future<void> down(SchemaBuilder builder) async {
    builder.drop('personal_access_tokens');
  }
}
