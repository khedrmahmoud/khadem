import 'package:khadem/khadem.dart'
    show ModelObserver;
import '../models/user.dart';

/// Observer for User model lifecycle events.
///
/// This demonstrates the complete observer pattern implementation with:
/// - Automatic UUID generation on creation
/// - Email notifications on user events
/// - Audit logging for changes
/// - Deletion prevention based on business rules
/// - Cache management on updates
class UserObserver extends ModelObserver<User> {
  // =============================================================================
  // CREATION EVENTS
  // =============================================================================

  /// Called before a new user is inserted into the database.
  ///
  /// Perfect for:
  /// - Setting default values
  /// - Generating UUIDs or slugs
  /// - Normalizing data
  @override
  void creating(User user) {
    print('🔵 [Observer] Creating user: ${user.email}');
    
    // Generate UUID if not set
    if (user.id == null) {
      // In production: user.uuid = Uuid().v4();
      print('   → Generated UUID for user');
    }
    
    // Set default status
    if (user.name == null || user.name!.isEmpty) {
      user.name = 'New User';
      print('   → Set default name');
    }
    
    // Normalize email
    if (user.email != null) {
      user.email = user.email!.toLowerCase().trim();
      print('   → Normalized email: ${user.email}');
    }
  }

  /// Called after a new user has been inserted into the database.
  ///
  /// Perfect for:
  /// - Sending welcome emails
  /// - Creating related records
  /// - Logging creation events
  /// - Triggering webhooks
  @override
  void created(User user) {
    print('✅ [Observer] User created successfully!');
    print('   → ID: ${user.id}');
    print('   → Email: ${user.email}');
    
    // Send welcome email (in production)
    // EmailService.send(user.email, 'welcome', {'name': user.name});
    print('   → Welcome email queued');
    
    // Create user profile (in production)
    // UserProfile.create({'user_id': user.id});
    print('   → User profile created');
    
    // Log audit trail
    print('   → Audit log: user.created (ID: ${user.id})');
  }

  // =============================================================================
  // UPDATE EVENTS
  // =============================================================================

  /// Called before a user is updated in the database.
  ///
  /// Perfect for:
  /// - Tracking changes
  /// - Validating updates
  /// - Recording who made the change
  @override
  void updating(User user) {
    print('🔵 [Observer] Updating user: ${user.id}');
    
    // Track who updated (in production)
    // user.updatedBy = getCurrentUserId();
    print('   → Updated by: System');
    
    // Log changes for audit trail
    print('   → Tracking changes...');
    
    // Increment version number (for optimistic locking)
    // user.version = (user.version ?? 0) + 1;
  }

  /// Called after a user has been updated in the database.
  ///
  /// Perfect for:
  /// - Clearing caches
  /// - Sending notifications
  /// - Updating search indexes
  /// - Syncing with external systems
  @override
  void updated(User user) {
    print('✅ [Observer] User updated successfully!');
    print('   → ID: ${user.id}');
    
    // Clear user cache
    print('   → Cache cleared: user:${user.id}');
    
    // Update search index (in production)
    // SearchService.updateIndex('users', user);
    print('   → Search index updated');
    
    // Send email notification if email changed
    // if (user.wasChanged('email')) {
    //   EmailService.send(user.email, 'email_changed');
    // }
    
    // Log audit trail
    print('   → Audit log: user.updated (ID: ${user.id})');
  }

  // =============================================================================
  // SAVE EVENTS (fires for both create and update)
  // =============================================================================

  /// Called before both insert and update operations.
  ///
  /// Perfect for:
  /// - Data normalization
  /// - Common validation
  /// - Setting timestamps
  @override
  void saving(User user) {
    print('💾 [Observer] Saving user...');
    
    // Normalize data
    if (user.email != null) {
      user.email = user.email!.toLowerCase().trim();
    }
    
    // Validate (in production, throw exception if invalid)
    if (user.email == null || !user.email!.contains('@')) {
      print('   ⚠️  Warning: Invalid email format');
    }
  }

  /// Called after both insert and update operations.
  ///
  /// Perfect for:
  /// - Common post-save logic
  /// - Cache invalidation
  /// - Broadcasting events
  @override
  void saved(User user) {
    print('✅ [Observer] User saved successfully!');
    
    // Invalidate all user-related caches
    print('   → All caches invalidated');
    
    // Broadcast user updated event (in production)
    // EventBus.emit('user.updated', user);
    print('   → Event broadcasted: user.updated');
  }

  // =============================================================================
  // DELETION EVENTS
  // =============================================================================

  /// Called before a user is deleted from the database.
  /// **CAN CANCEL THE DELETION** by returning false.
  ///
  /// Perfect for:
  /// - Preventing deletion based on business rules
  /// - Confirming user intentions
  /// - Checking for related data
  @override
  bool deleting(User user) {
    print('🔴 [Observer] Attempting to delete user: ${user.id}');
    
    // Example 1: Prevent deletion if user has active subscriptions
    // if (user.hasActiveSubscription) {
    //   print('   ❌ Cannot delete user with active subscription');
    //   return false; // Cancel deletion
    // }
    
    // Example 2: Prevent deletion of admin users
    // if (user.role == 'admin') {
    //   print('   ❌ Cannot delete admin users');
    //   return false; // Cancel deletion
    // }
    
    // Example 3: Soft delete instead of hard delete
    // if (!user.forceDelete) {
    //   user.deletedAt = DateTime.now();
    //   user.save();
    //   print('   → Soft deleted instead');
    //   return false; // Cancel hard deletion
    // }
    
    // Allow deletion
    print('   ✓ Deletion allowed');
    return true;
  }

  /// Called after a user has been deleted from the database.
  ///
  /// Perfect for:
  /// - Cleaning up related data
  /// - Removing from caches
  /// - Archiving user data
  /// - Sending notifications
  @override
  void deleted(User user) {
    print('✅ [Observer] User deleted successfully!');
    print('   → ID: ${user.id}');
    
    // Delete user files (in production)
    // StorageService.deleteDirectory('users/${user.id}');
    print('   → User files deleted');
    
    // Remove from all caches
    print('   → Removed from cache: user:${user.id}');
    
    // Archive user data for GDPR compliance (in production)
    // ArchiveService.archiveUser(user);
    print('   → User data archived');
    
    // Notify admins
    print('   → Admin notification sent: User ${user.email} deleted');
    
    // Log audit trail
    print('   → Audit log: user.deleted (ID: ${user.id})');
  }

  // =============================================================================
  // RETRIEVAL EVENTS
  // =============================================================================

  /// Called after a user has been retrieved from the database.
  ///
  /// Perfect for:
  /// - Decrypting sensitive data
  /// - Loading additional data
  /// - Tracking access
  /// - Applying business logic transformations
  @override
  void retrieved(User user) {
    print('📥 [Observer] User retrieved from database');
    print('   → ID: ${user.id}');
    print('   → Email: ${user.email}');
    
    // Decrypt sensitive fields (in production)
    // if (user.ssn != null) {
    //   user.ssn = decrypt(user.ssn);
    // }
    
    // Track last accessed timestamp (in production)
    // trackUserAccess(user.id);
    print('   → Access tracked');
    
    // Load additional computed data
    // user.fullName = '${user.firstName} ${user.lastName}';
  }

  // =============================================================================
  // SOFT DELETE EVENTS (if using SoftDeletes mixin)
  // =============================================================================

  /// Called before a soft-deleted user is restored.
  /// **CAN CANCEL THE RESTORATION** by returning false.
  ///
  /// Perfect for:
  /// - Validating restoration
  /// - Checking business rules
  /// - Confirming user intentions
  @override
  bool restoring(User user) {
    print('🔄 [Observer] Attempting to restore user: ${user.id}');
    
    // Example: Check if restoration is allowed
    // if (!canRestoreUser(user.id)) {
    //   print('   ❌ Restoration not allowed');
    //   return false; // Cancel restoration
    // }
    
    print('   ✓ Restoration allowed');
    return true;
  }

  /// Called after a soft-deleted user has been restored.
  ///
  /// Perfect for:
  /// - Sending restoration notifications
  /// - Re-enabling related services
  /// - Logging restoration events
  @override
  void restored(User user) {
    print('✅ [Observer] User restored successfully!');
    print('   → ID: ${user.id}');
    
    // Send account restored email (in production)
    // EmailService.send(user.email, 'account_restored');
    print('   → Restoration email sent');
    
    // Re-enable user services
    print('   → User services re-enabled');
    
    // Log audit trail
    print('   → Audit log: user.restored (ID: ${user.id})');
  }

  /// Called before a user is permanently deleted (force delete).
  /// **CAN CANCEL THE FORCE DELETION** by returning false.
  ///
  /// Perfect for:
  /// - Requiring additional authorization
  /// - Final confirmations
  /// - Checking for permanent deletion permissions
  @override
  bool forceDeleting(User user) {
    print('⚠️  [Observer] Attempting to PERMANENTLY delete user: ${user.id}');
    
    // Example: Require admin approval for permanent deletion
    // if (!isAdmin()) {
    //   print('   ❌ Only admins can permanently delete users');
    //   return false; // Cancel force deletion
    // }
    
    // Example: Require explicit confirmation
    // if (!user.confirmedForceDelete) {
    //   print('   ❌ Force deletion not confirmed');
    //   return false; // Cancel force deletion
    // }
    
    print('   ⚠️  PERMANENT deletion allowed');
    return true;
  }

  /// Called after a user has been permanently deleted.
  ///
  /// Perfect for:
  /// - Permanently removing all traces
  /// - Deleting files
  /// - Removing from all systems
  @override
  void forceDeleted(User user) {
    print('✅ [Observer] User PERMANENTLY deleted!');
    print('   → ID: ${user.id}');
    
    // Permanently delete all user files
    print('   → All user files permanently deleted');
    
    // Remove from all systems
    print('   → Removed from all systems');
    
    // Cannot archive (already gone)
    print('   → No archive (permanent deletion)');
    
    // Log audit trail
    print('   → Audit log: user.force_deleted (ID: ${user.id})');
  }
}
