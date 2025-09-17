import 'package:khadem/khadem_dart.dart';

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
// khadem make:migration create_something_table
//
// The migrate command will:
// 1. Load this registry file
// 2. Instantiate all migration classes
// 3. Run them in order
// 4. Track execution status in the migrations table
