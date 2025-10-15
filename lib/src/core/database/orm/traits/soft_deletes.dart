import 'package:khadem/khadem.dart';

/// Mixin that adds soft delete functionality to models
/// 
/// Soft deletes allow you to "delete" records without actually removing them
/// from the database. Instead, a `deleted_at` timestamp is set.
/// 
/// ## Usage
/// 
/// ```dart
/// class Post extends KhademModel<Post> with SoftDeletes {
///   // Your model properties...
/// }
/// 
/// // Soft delete (sets deleted_at)
/// await post.delete();
/// 
/// // Restore a soft-deleted record
/// await post.restore();
/// 
/// // Permanently delete
/// await post.forceDelete();
/// 
/// // Query with soft deletes
/// final posts = await Post.query().get(); // Excludes deleted
/// final all = await Post.query().withTrashed().get(); // Includes deleted
/// final trashed = await Post.query().onlyTrashed().get(); // Only deleted
/// ```
/// 
/// ## Database Requirements
/// 
/// Your table must have a `deleted_at` column (nullable timestamp):
/// 
/// ```sql
/// ALTER TABLE posts ADD COLUMN deleted_at TIMESTAMP NULL;
/// ```
/// 
/// ## Customization
/// 
/// Override `deletedAtColumn` to use a different column name:
/// 
/// ```dart
/// class Post extends KhademModel<Post> with SoftDeletes {
///   @override
///   String get deletedAtColumn => 'removed_at';
/// }
/// ```
mixin SoftDeletes<T> on KhademModel<T> {
  /// The name of the "deleted at" column
  /// 
  /// Override this to use a different column name.
  String get deletedAtColumn => 'deleted_at';

  /// Get the deleted_at value
  DateTime? get deletedAt {
    final value = getField(deletedAtColumn);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Set the deleted_at value
  set deletedAt(DateTime? value) {
    setField(deletedAtColumn, value);
  }

  /// Determine if the model instance has been soft-deleted
  bool get trashed => deletedAt != null;

  /// Soft delete the model (set deleted_at timestamp)
  /// 
  /// This overrides the default delete() behavior to perform a soft delete
  /// instead of permanently removing the record from the database.
  Future<bool> softDelete() async {
    if (trashed) {
      return false; // Already deleted
    }

    deletedAt = DateTime.now().toUtc();
    
    // Fire deleting event
    await event.beforeDelete();

    // Update the deleted_at column
    await db.save();

    await event.afterDelete();

    return true;
  }

  /// Restore a soft-deleted model
  /// 
  /// Sets deleted_at to null, making the record "active" again.
  Future<bool> restore() async {
    if (!trashed) {
      return false; // Not deleted, nothing to restore
    }

    // Call observer beforeRestore hook
    final allowed = event.beforeRestore();
    if (!allowed) {
      return false; // Restoration cancelled by observer
    }

    deletedAt = null;

    // Save the change
    await db.save();

    // Call observer afterRestore hook
    event.afterRestore();

    return true;
  }

  /// Permanently delete the model from the database
  /// 
  /// This bypasses soft delete and actually removes the record.
  Future<bool> forceDelete() async {
    // Call observer beforeForceDelete hook
    final allowed = event.beforeForceDelete();
    if (!allowed) {
      return false; // Force deletion cancelled by observer
    }

    // Permanently delete
    await db.delete();

    // Call observer afterForceDelete hook
    event.afterForceDelete();

    return true;
  }

  /// Override default delete to use soft delete
  /// 
  /// To permanently delete, use forceDelete() instead.
  @override
  Future<bool> delete() async {
    return softDelete();
  }

  /// Check if the model is currently soft deleted
  bool get isTrashed => trashed;

  /// Check if the model is NOT soft deleted
  bool get isNotTrashed => !trashed;
}

/// Extension methods for QueryBuilder to work with soft deletes
/// 
/// Note: These methods need to be manually applied to query builders
/// until automatic scope detection is implemented.
extension SoftDeleteQueryExtensions<T extends KhademModel<T>> on QueryBuilderInterface<T> {
  /// Include soft-deleted records in the query results
  /// 
  /// By default, queries exclude soft-deleted records. This method
  /// allows you to retrieve all records, including soft-deleted ones.
  /// 
  /// Example:
  /// ```dart
  /// final allPosts = await Post.query().withTrashed().get();
  /// ```
  QueryBuilderInterface<T> withTrashed() {
    // Remove the deleted_at IS NULL constraint if it exists
    // This is a pattern - actual implementation depends on query builder
    return this;
  }

  /// Only retrieve soft-deleted records
  /// 
  /// Example:
  /// ```dart
  /// final deletedPosts = await Post.query().onlyTrashed().get();
  /// ```
  QueryBuilderInterface<T> onlyTrashed() {
    return whereNotNull('deleted_at');
  }

  /// Exclude soft-deleted records (default behavior)
  /// 
  /// This is the default behavior, but can be useful to explicitly
  /// state the intent or override a previous withTrashed() call.
  /// 
  /// Example:
  /// ```dart
  /// final activePosts = await Post.query().withoutTrashed().get();
  /// ```
  QueryBuilderInterface<T> withoutTrashed() {
    return whereNull('deleted_at');
  }
}
