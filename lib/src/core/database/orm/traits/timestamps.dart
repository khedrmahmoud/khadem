import '../../model_base/concerns/has_attributes.dart';
import '../../model_base/concerns/interacts_with_database.dart';

mixin Timestamps<T> on InteractsWithDatabase<T>, HasAttributes<T> {
  /// Whether to use timestamps on this model
  bool get timestamps => true;

  /// The name of the "created at" column
  String get createdAtColumn => 'created_at';

  /// The name of the "updated at" column
  String get updatedAtColumn => 'updated_at';

  /// Get the created_at value
  DateTime? get createdAt {
    if (!timestamps) return null;
    final value = getAttribute(createdAtColumn);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Set the created_at value
  set createdAt(DateTime? value) {
    if (!timestamps) return;
    setAttribute(createdAtColumn, value);
  }

  /// Get the updated_at value
  DateTime? get updatedAt {
    if (!timestamps) return null;
    final value = getAttribute(updatedAtColumn);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Set the updated_at value
  set updatedAt(DateTime? value) {
    if (!timestamps) return;
    setAttribute(updatedAtColumn, value);
  }

  /// Update the model's timestamp before saving
  void _updateTimestamps({required bool isCreating}) {
    if (!timestamps) return;

    final now = DateTime.now().toUtc();

    if (isCreating) {
      // Set created_at only on creation
      if (createdAt == null) {
        setAttribute(createdAtColumn, now);
      }
    }

    // Always update updated_at
    setAttribute(updatedAtColumn, now);
  }

  /// Override save to automatically update timestamps
  @override
  Future<bool> save() async {
    final isCreating = !exists;
    _updateTimestamps(isCreating: isCreating);
    return super.save();
  }
}
