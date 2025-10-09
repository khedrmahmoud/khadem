import 'dart:io' show exit;
import 'package:khadem/khadem.dart';
import 'app/models/user.dart';
import 'core/kernel.dart';

/// Observer Pattern Example
///
/// This demonstrates the Model Observer pattern in action.
/// Observers provide a clean way to handle model lifecycle events
/// without cluttering your models with business logic.
///
/// Run this example:
/// ```
/// dart run example/lib/observer_example.dart
/// ```
Future<void> main() async {
  print('═══════════════════════════════════════════════════════');
  print('🎯 Model Observer Pattern Example');
  print('═══════════════════════════════════════════════════════\n');

  // Bootstrap the application (registers observers)
  await Kernel.bootstrap();

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('Example 1: Creating a User');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final user1 = User(
    name: 'John Doe',
    email: 'JOHN@EXAMPLE.COM', // Will be normalized by observer
    password: 'secret123',
  );

  print('Creating user...');
  // This will trigger:
  // 1. creating() - normalizes email, sets defaults
  // 2. saving() - additional validation
  // 3. (database insert would happen here)
  // 4. created() - sends welcome email, creates profile
  // 5. saved() - clears caches, broadcasts event

  print('User created: ${user1.name} (${user1.email})');

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('Example 2: Updating a User');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  user1.id = 1; // Simulate existing user
  user1.name = 'Jane Doe';

  print('Updating user...');
  // This will trigger:
  // 1. updating() - tracks changes, logs audit
  // 2. saving() - validates data
  // 3. (database update would happen here)
  // 4. updated() - clears caches, updates search index
  // 5. saved() - broadcasts event

  print('User updated: ${user1.name}');

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('Example 3: Retrieving a User');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  print('Retrieving user from database...');
  // In a real app: final user = await User.query().findById(1);
  // This would trigger:
  // - retrieved() - decrypts sensitive data, tracks access

  final retrievedUser = User(
    id: 1,
    name: 'Jane Doe',
    email: 'jane@example.com',
  );
  // Simulate retrieval event
  retrievedUser.event.afterRetrieve();

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('Example 4: Deleting a User (Allowed)');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final userToDelete = User(
    id: 2,
    name: 'Test User',
    email: 'test@example.com',
  );

  print('Attempting to delete user...');
  // This will trigger:
  // 1. deleting() - checks business rules, allows deletion
  // 2. (database delete would happen here)
  // 3. deleted() - cleans up files, archives data

  // Simulate delete event
  final canDelete = await userToDelete.event.beforeDelete();
  if (canDelete) {
    await userToDelete.event.afterDelete();
    print('✅ User deleted successfully!');
  } else {
    print('❌ Deletion was cancelled by observer');
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('Example 5: Soft Delete and Restore');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final softDeleteUser = User(
    id: 3,
    name: 'Soft Delete User',
    email: 'softdelete@example.com',
  );

  print('Attempting to restore soft-deleted user...');
  // This will trigger:
  // 1. restoring() - validates restoration is allowed
  // 2. restored() - sends notification, re-enables services

  final canRestore = softDeleteUser.event.beforeRestore();
  if (canRestore) {
    softDeleteUser.event.afterRestore();
    print('✅ User restored successfully!');
  } else {
    print('❌ Restoration was cancelled by observer');
  }

  print('\n═══════════════════════════════════════════════════════');
  print('✅ Observer Pattern Example Complete!');
  print('═══════════════════════════════════════════════════════\n');

  print('Key Takeaways:');
  print('');
  print('1. Observers keep models clean by moving business logic out');
  print('2. Multiple observers can be registered for the same model');
  print('3. Observers can cancel operations (deleting, restoring, etc.)');
  print('4. All lifecycle events are covered (12 hooks available)');
  print('5. Perfect for:');
  print('   - Sending notifications');
  print('   - Audit logging');
  print('   - Cache management');
  print('   - Data validation');
  print('   - File cleanup');
  print('   - Event broadcasting');
  print('');
  print('See app/observers/user_observer.dart for implementation details.');
  print('');

  exit(0);
}
