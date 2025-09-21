import 'package:khadem/khadem.dart';

import '0_create_personal_access_token_table.dart';
import '0_create_users_table.dart';

// Migration registry - automatically maintained by the migration generator
// This file is used by the 'khadem migrate' command to discover and run migrations
List<MigrationFile> migrationsFiles = <MigrationFile>[
  // User-related migrations
  CreateUsersTable(),
  CreatePersonalAccessTokenTable(),

  // Add new migrations here as you create them
  // Example: CreatePostsTable(),
  // Example: CreateCommentsTable(),
];

// Note: This file is automatically updated when you run:
// khadem make:migration --name=<MigrationName>
