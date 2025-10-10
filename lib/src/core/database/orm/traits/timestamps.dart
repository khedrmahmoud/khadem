import 'package:khadem/khadem.dart';

/// Mixin that adds automatic timestamp management to models
///
/// This mixin automatically manages `created_at` and `updated_at` timestamps
/// when creating or updating model records.
///
/// ## Usage
///
/// ```dart
/// class User extends KhademModel<User> with Timestamps {
///   int? id;
///   String? name;
///   String? email;
///
///   // created_at and updated_at are automatically managed
/// }
///
/// // Creating a record
/// final user = User()
///   ..name = 'John'
///   ..email = 'john@example.com';
/// await user.save(); // created_at and updated_at are set automatically
///
/// // Updating a record
/// user.name = 'Jane';
/// await user.save(); // updated_at is updated automatically
///
/// // Accessing timestamps
/// print(user.createdAt);
/// print(user.updatedAt);
/// ```
///
/// ## Database Requirements
///
/// Your table must have `created_at` and `updated_at` columns (timestamps):
///
/// ```sql
/// ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
/// ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
/// ```
///
/// ## Customization
///
/// ### Disable Timestamps
///
/// ```dart
/// class Session extends KhademModel<Session> with Timestamps {
///   @override
///   bool get timestamps => false;
/// }
/// ```
///
/// ### Custom Column Names
///
/// ```dart
/// class Post extends KhademModel<Post> with Timestamps {
///   @override
///   String get createdAtColumn => 'published_at';
///
///   @override
///   String get updatedAtColumn => 'modified_at';
/// }
/// ```
mixin Timestamps<T> on KhademModel<T> {
  /// Whether to use timestamps on this model
  ///
  /// Override this to disable timestamps for specific models.
  bool get timestamps => true;

  /// The name of the "created at" column
  ///
  /// Override this to use a different column name.
  String get createdAtColumn => 'created_at';

  /// The name of the "updated at" column
  ///
  /// Override this to use a different column name.
  String get updatedAtColumn => 'updated_at';

  DateTime? _createdAt;
  DateTime? _updatedAt;

  @override
  List<String> get fillable =>
      timestamps ? ['created_at', 'updated_at', ...super.fillable] : [];

  /// Get the created_at value
  DateTime? get createdAt {
    if (!timestamps) return null;

    final value = rawData[createdAtColumn];
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return _createdAt;
  }

  /// Set the created_at value
  set createdAt(DateTime? value) {
    if (!timestamps) return;
    _createdAt = value;
  }

  /// Get the updated_at value
  DateTime? get updatedAt {
    if (!timestamps) return null;

    final value = rawData[updatedAtColumn];
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return _updatedAt;
  }

  /// Set the updated_at value
  set updatedAt(DateTime? value) {
    if (!timestamps) return;
    _updatedAt = value;
  }

  /// Update the model's timestamp before saving
  void _updateTimestamps({required bool isCreating}) {
    if (!timestamps) return;

    final now = DateTime.now().toUtc();

    if (isCreating) {
      // Set created_at only on creation
      if (createdAt == null) {
        createdAt = now;
      }
    }

    // Always update updated_at
    updatedAt = now;
  }

  /// Override save to automatically update timestamps
  @override
  Future<void> save() async {
    final isCreating = id == null;
    _updateTimestamps(isCreating: isCreating);
    await super.save();
  }

  /// Update only the updated_at timestamp without modifying other fields
  ///
  /// Useful when you want to "touch" a record to mark it as recently accessed.
  ///
  /// Example:
  /// ```dart
  /// await user.touch();
  /// ```
  Future<void> touch() async {
    if (!timestamps) return;

    updatedAt = DateTime.now().toUtc();

    // Only update the updated_at column
    if (id != null) {
      await query.where('id', '=', id).update({updatedAtColumn: updatedAt});
    }
  }

  /// Update the model's timestamps manually
  ///
  /// Useful when you need to set custom timestamp values.
  ///
  /// Example:
  /// ```dart
  /// user.setTimestamps(
  ///   createdAt: DateTime(2024, 1, 1),
  ///   updatedAt: DateTime(2024, 1, 2),
  /// );
  /// ```
  void setTimestamps({
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    if (!timestamps) return;

    if (createdAt != null) {
      this.createdAt = createdAt;
    }

    if (updatedAt != null) {
      this.updatedAt = updatedAt;
    }
  }

  /// Get the age of the record (time since creation)
  ///
  /// Example:
  /// ```dart
  /// final age = user.age;
  /// print('User created ${age.inDays} days ago');
  /// ```
  Duration? get age {
    if (createdAt == null) return null;
    return DateTime.now().difference(createdAt!);
  }

  /// Get the time since last update
  ///
  /// Example:
  /// ```dart
  /// final timeSinceUpdate = post.timeSinceUpdate;
  /// print('Last updated ${timeSinceUpdate?.inHours} hours ago');
  /// ```
  Duration? get timeSinceUpdate {
    if (updatedAt == null) return null;
    return DateTime.now().difference(updatedAt!);
  }

  /// Check if the record was recently created
  ///
  /// Example:
  /// ```dart
  /// if (user.wasRecentlyCreated(hours: 24)) {
  ///   print('New user!');
  /// }
  /// ```
  bool wasRecentlyCreated({int hours = 1}) {
    if (createdAt == null) return false;
    final threshold = DateTime.now().subtract(Duration(hours: hours));
    return createdAt!.isAfter(threshold);
  }

  /// Check if the record was recently updated
  ///
  /// Example:
  /// ```dart
  /// if (post.wasRecentlyUpdated(minutes: 30)) {
  ///   print('Recently modified');
  /// }
  /// ```
  bool wasRecentlyUpdated({int minutes = 30}) {
    if (updatedAt == null) return false;
    final threshold = DateTime.now().subtract(Duration(minutes: minutes));
    return updatedAt!.isAfter(threshold);
  }
}

/// Extension to make timestamp columns automatically fillable
///
/// This is a helper to ensure timestamp columns are included in fillable lists.
extension TimestampsExtension<T extends KhademModel<T>> on Timestamps<T> {
  /// Get timestamp column names
  List<String> get timestampColumns =>
      timestamps ? [createdAtColumn, updatedAtColumn] : [];
}
