import '../../model_base/concerns/has_attributes.dart';
import '../../model_base/concerns/has_events.dart';
import '../../model_base/concerns/interacts_with_database.dart';
import '../model_lifecycle.dart';

mixin SoftDeletes<T>
    on InteractsWithDatabase<T>, HasAttributes<T>, HasEvents<T> {
  /// The name of the "deleted at" column
  String get deletedAtColumn => 'deleted_at';

  /// Get the deleted_at value
  DateTime? get deletedAt {
    final value = getAttribute(deletedAtColumn);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Set the deleted_at value
  set deletedAt(DateTime? value) {
    setAttribute(deletedAtColumn, value);
  }

  /// Determine if the model instance has been soft-deleted
  bool get trashed => deletedAt != null;

  /// Soft delete the model (set deleted_at timestamp)
  Future<bool> softDelete({DateTime? at}) async {
    if (trashed) return false;

    if (await fireModelEvent(ModelLifecycle.deleting) == false) return false;

    deletedAt = (at ?? DateTime.now()).toUtc();
    await save();

    await fireModelEvent(ModelLifecycle.deleted, halt: false);
    return true;
  }

  /// Restore a soft-deleted model
  Future<bool> restore({bool touch = true}) async {
    if (!trashed) return false;

    if (await fireModelEvent(ModelLifecycle.restoring) == false) return false;

    deletedAt = null;
    if (touch) {
      await save();
    } else {
      await query.where(primaryKey, '=', getKey()).update({deletedAtColumn: null});
      (this as HasAttributes).syncOriginal();
    }

    await fireModelEvent(ModelLifecycle.restored, halt: false);
    return true;
  }

  /// Permanently delete the model from the database
  Future<bool> forceDelete() async {
    if (await fireModelEvent(ModelLifecycle.forceDeleting) == false) {
      return false;
    }

    await super.delete();

    await fireModelEvent(ModelLifecycle.forceDeleted, halt: false);
    return true;
  }

  /// Override default delete to use soft delete
  @override
  Future<bool> delete() async {
    return softDelete();
  }

  /// Check if the model is currently soft deleted
  bool get isTrashed => trashed;

  /// Check if the model is NOT soft deleted
  bool get isNotTrashed => !trashed;
}
