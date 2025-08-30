import 'package:khadem/khadem_dart.dart';

import '0_create_personal_access_token_table.dart';
import '0_create_users_table.dart';

List<MigrationFile> migrationsFiles = <MigrationFile>[
  CreateUsersTable(),
  CreatePersonalAccessTokenTable(),
];
