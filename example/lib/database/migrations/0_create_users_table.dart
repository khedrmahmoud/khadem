import 'package:khadem/contracts.dart' show MigrationFile, SchemaBuilder;

class CreateUsersTable extends MigrationFile {
  @override
  Future<void> up(SchemaBuilder builder) async {
    builder.create('users', (table) {
      table.id();
      table.string('name');
      table.string('email').unique();
      table.string('password');
      table.timestamps();
    });
  }

  @override
  Future<void> down(SchemaBuilder builder) async {
    builder.dropIfExists('users');
  }
}
