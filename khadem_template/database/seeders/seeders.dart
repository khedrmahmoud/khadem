import 'package:khadem/khadem.dart';

import 'user_seeder.dart';

// Seeder registry - automatically maintained by the seeder generator
// This file is used by the 'khadem db:seed' command to discover and run seeders
// The seed command will:
// 1. Load this registry file
// 2. Instantiate all seeder classes using Dart mirrors
// 3. Run them in order
// 4. Track execution status

List<Seeder> seedersList = <Seeder>[
  // User-related seeders
  UserSeeder(),
];

// Note: This file is automatically updated when you run:
// khadem make:seeder create_something_seeder
//
// The db:seed command will:
// 1. Load this registry file using Dart mirrors
// 2. Instantiate all seeder classes dynamically
// 3. Run them in the order specified
// 4. Handle errors gracefully
//
// To create a new seeder:
// khadem make:seeder create_users_seeder
//
// This will create:
// - database/seeders/create_users_seeder.dart
// - Update this registry file automatically
