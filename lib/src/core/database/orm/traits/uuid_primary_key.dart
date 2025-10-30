import 'package:uuid/uuid.dart';

/// Mixin that adds UUID primary key support to models
///
/// Automatically generates a UUID when creating a new model.
/// Use with ModelObserver to auto-generate on creation.
///
/// Example:
/// ```dart
/// class User extends KhademModel<User> with UuidPrimaryKey {
///   // The uuid field will be auto-generated
/// }
///
/// // With observer for auto-generation:
/// class UserObserver extends ModelObserver<User> {
///   @override
///   void creating(User user) {
///     user.ensureUuidGenerated();
///   }
/// }
///
/// // Manual generation:
/// final user = User();
/// user.generateUuid();
/// print(user.uuid); // "550e8400-e29b-41d4-a716-446655440000"
/// ```
mixin UuidPrimaryKey {
  /// The UUID value
  String? uuid;

  /// UUID generator instance
  static const Uuid _uuidGenerator = Uuid();

  /// Generate a new UUID v4
  ///
  /// Generates a random UUID using the v4 algorithm.
  /// Overwrites any existing UUID.
  void generateUuid() {
    uuid = _uuidGenerator.v4();
  }

  /// Generate UUID only if not already set
  ///
  /// Useful in observers to ensure UUID exists without overwriting.
  void ensureUuidGenerated() {
    if (!hasUuid) {
      generateUuid();
    }
  }

  /// Check if UUID has been generated
  bool get hasUuid => uuid != null && uuid!.isNotEmpty;

  /// Get UUID or generate if missing
  ///
  /// Convenience method that ensures UUID exists and returns it.
  String getOrGenerateUuid() {
    ensureUuidGenerated();
    return uuid!;
  }
}
