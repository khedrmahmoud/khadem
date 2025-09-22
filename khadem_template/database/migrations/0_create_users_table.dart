import 'package:khadem/khadem.dart' show MigrationFile;

class CreateUsersTable extends MigrationFile {
  @override
  Future<void> up(builder) async {
    builder.create('users', (table) {
      table.id();
      table.string('name');
      table.string('email').unique();
      table.string('password');
      table.timestamps();
    });
  }

  @override
  Future<void> down(builder) async {
    builder.dropIfExists('users');
  }
}
