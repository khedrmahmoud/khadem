import 'package:khadem/khadem_dart.dart';

import '1_create_users_table.dart';
import '2_create_personal_access_token_table.dart';

List<MigrationFile> migrationFiles = <MigrationFile>[
  CreateUsersTable(),
  CreatePersonalAccessTokenTable(),
];
