import '../../../application/khadem.dart';
import '../orm/model_events.dart';
import '../orm/observers/model_observer.dart';
import '../orm/observers/observer_registry.dart';
import 'khadem_model.dart';

class EventModel<T> {
  final KhademModel<T> model;

  EventModel(this.model);

  Future<void> fireEvent(String Function(String) eventBuilder) async {
    await Khadem.eventBus
        .emit(eventBuilder(model.modelName.toLowerCase()), model);
  }

  /// Get observers for this model's runtime type
  List<ModelObserver> _getObservers() {
    try {
      final modelType = model.runtimeType;
      return ObserverRegistry().getObserversByType(modelType);
    } catch (e) {
      return [];
    }
  }

  /// Call observer methods for a specific event
  void _callObservers(void Function(dynamic observer) callback) {
    final observers = _getObservers();
    for (final observer in observers) {
      try {
        callback(observer);
      } catch (e) {
        // Log error but don't break execution
        print('Observer error: $e');
      }
    }
  }

  /// Call observer methods that can cancel operations (return bool)
  bool _callCancelableObservers(bool Function(dynamic observer) callback) {
    final observers = _getObservers();
    for (final observer in observers) {
      try {
        final result = callback(observer);
        if (!result) {
          return false; // Operation cancelled
        }
      } catch (e) {
        print('Observer error: $e');
        return false; // Cancel on error
      }
    }
    return true; // Allow operation
  }

  Future<void> beforeCreate() async {
    _callObservers((observer) => observer.creating(model));
    _callObservers((observer) => observer.saving(model));
    await fireEvent(ModelEvents.creating);
  }

  Future<void> afterCreate() async {
    _callObservers((observer) => observer.created(model));
    _callObservers((observer) => observer.saved(model));
    await fireEvent(ModelEvents.created);
  }

  Future<void> beforeUpdate() async {
    _callObservers((observer) => observer.updating(model));
    _callObservers((observer) => observer.saving(model));
    await fireEvent(ModelEvents.updating);
  }

  Future<void> afterUpdate() async {
    _callObservers((observer) => observer.updated(model));
    _callObservers((observer) => observer.saved(model));
    await fireEvent(ModelEvents.updated);
  }

  Future<bool> beforeDelete() async {
    final allowed =
        _callCancelableObservers((observer) => observer.deleting(model));
    if (!allowed) return false;

    await fireEvent(ModelEvents.deleting);
    return true;
  }

  Future<void> afterDelete() async {
    _callObservers((observer) => observer.deleted(model));
    await fireEvent(ModelEvents.deleted);
  }

  /// Observer hook for restoring soft-deleted models
  bool beforeRestore() {
    return _callCancelableObservers((observer) => observer.restoring(model));
  }

  void afterRestore() {
    _callObservers((observer) => observer.restored(model));
  }

  /// Observer hook for force deleting soft-deleted models
  bool beforeForceDelete() {
    return _callCancelableObservers(
      (observer) => observer.forceDeleting(model),
    );
  }

  void afterForceDelete() {
    _callObservers((observer) => observer.forceDeleted(model));
  }

  /// Observer hook for retrieving models
  void afterRetrieve() {
    _callObservers((observer) => observer.retrieved(model));
  }
}
