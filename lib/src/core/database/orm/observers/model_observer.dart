import '../../model_base/khadem_model.dart';

/// Base class for model observers.
///
/// Observers provide a clean way to separate event handling logic from your models.
/// They allow you to listen to model lifecycle events and execute code accordingly.
///
/// Example:
/// ```dart
/// class UserObserver extends ModelObserver<User> {
///   @override
///   void creating(User user) {
///     user.uuid = Uuid().v4();
///     user.createdBy = getCurrentUserId();
///   }
///
///   @override
///   void created(User user) {
///     print('New user created: ${user.email}');
///     sendWelcomeEmail(user);
///   }
///
///   @override
///   bool deleting(User user) {
///     // Prevent deletion if user has posts
///     if (user.postsCount > 0) {
///       print('Cannot delete user with posts');
///       return false; // Cancel deletion
///     }
///     return true; // Allow deletion
///   }
/// }
///
/// // Register observer
/// User.observe(UserObserver());
/// ```
abstract class ModelObserver<T extends KhademModel<T>> {
  /// Called before a model is created (inserted into database).
  ///
  /// This is called before the INSERT query is executed.
  /// You can modify the model here (e.g., set UUIDs, default values).
  void creating(T model) {}

  /// Called after a model has been created (inserted into database).
  ///
  /// This is called after the INSERT query succeeds.
  /// The model will have an ID at this point.
  void created(T model) {}

  /// Called before a model is updated.
  ///
  /// This is called before the UPDATE query is executed.
  /// You can modify the model here or validate changes.
  void updating(T model) {}

  /// Called after a model has been updated.
  ///
  /// This is called after the UPDATE query succeeds.
  void updated(T model) {}

  /// Called before a model is saved (either created or updated).
  ///
  /// This is called before both INSERT and UPDATE queries.
  void saving(T model) {}

  /// Called after a model has been saved (either created or updated).
  ///
  /// This is called after both INSERT and UPDATE queries succeed.
  void saved(T model) {}

  /// Called before a model is deleted.
  ///
  /// Return `false` to cancel the deletion.
  /// Return `true` to allow the deletion to proceed.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool deleting(User user) {
  ///   if (user.isAdmin) {
  ///     return false; // Prevent deletion
  ///   }
  ///   return true; // Allow deletion
  /// }
  /// ```
  bool deleting(T model) => true;

  /// Called after a model has been deleted.
  ///
  /// This is called after the DELETE query succeeds.
  void deleted(T model) {}

  /// Called before a model is retrieved from the database.
  ///
  /// This is called before the SELECT query is executed.
  void retrieving(T model) {}

  /// Called after a model has been retrieved from the database.
  ///
  /// This is called after the SELECT query succeeds and the model is hydrated.
  void retrieved(T model) {}

  /// Called before a model is restored (for soft deletes).
  ///
  /// Return `false` to cancel the restoration.
  /// Return `true` to allow the restoration to proceed.
  bool restoring(T model) => true;

  /// Called after a model has been restored (for soft deletes).
  ///
  /// This is called after the soft delete restoration succeeds.
  void restored(T model) {}

  /// Called before a model is force deleted (permanent deletion with soft deletes).
  ///
  /// Return `false` to cancel the force deletion.
  /// Return `true` to allow the force deletion to proceed.
  bool forceDeleting(T model) => true;

  /// Called after a model has been force deleted.
  ///
  /// This is called after the permanent deletion succeeds.
  void forceDeleted(T model) {}
}
