import '../../../application/khadem.dart';
import '../../../contracts/events/event.dart';
import '../orm/model_events.dart';
import '../orm/observers/model_observer.dart';
import '../orm/observers/observer_registry.dart';
import 'khadem_model.dart';

class EventModel<T> {
  final KhademModel<T> model;

  EventModel(this.model);

  Future<void> dispatch(Event event) async {
    await Khadem.events.dispatch(event);
  }

  /// Get observers for this model's runtime type
  List<ModelObserver> _getObservers() {
    try {
      final modelType = model.runtimeType;
      return ObserverRegistry().getObserversByType(modelType);
    } catch (e, stack) {
      Khadem.logger.error('Failed to get observers for ${model.runtimeType}', context: {'error': e}, stackTrace: stack);
      return [];
    }
  }

  /// Call observer methods for a specific event
  void _callObservers(void Function(dynamic observer) callback) {
    final observers = _getObservers();
    for (final observer in observers) {
      try {
        callback(observer);
      } catch (e, stack) {
        Khadem.logger.error('Observer error in ${model.runtimeType}', context: {'error': e}, stackTrace: stack);
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
      } catch (e, stack) {
        Khadem.logger.error('Observer error in ${model.runtimeType}', context: {'error': e}, stackTrace: stack);
        return false; // Cancel on error
      }
    }
    return true; // Allow operation
  }

  Future<bool> _dispatchCustomEvent(String lifecycle) async {
    final map = model.dispatchesEvents;
    if (map.containsKey(lifecycle)) {
      final eventBuilder = map[lifecycle];
      if (eventBuilder != null) {
        final event = eventBuilder(model as T);
        await dispatch(event);
        if (event is StoppableEvent && event.isPropagationStopped) {
          return false;
        }
      }
    }
    return true;
  }

  Future<bool> beforeCreate() async {
    final allowed = _callCancelableObservers((observer) => observer.creating(model));
    if (!allowed) return false;

    final event = ModelCreating(model as T);
    await dispatch(event);
    
    if (event.isPropagationStopped) return false;

    return _dispatchCustomEvent('creating');
  }

  Future<void> afterCreate() async {
    _callObservers((observer) => observer.created(model));
    _callObservers((observer) => observer.saved(model));
    await dispatch(ModelCreated(model as T));
    await _dispatchCustomEvent('created');
    await _dispatchCustomEvent('saved');
  }

  Future<bool> beforeUpdate() async {
    final allowed = _callCancelableObservers((observer) => observer.updating(model));
    if (!allowed) return false;

    final event = ModelUpdating(model as T);
    await dispatch(event);

    if (event.isPropagationStopped) return false;

    return _dispatchCustomEvent('updating');
  }

  Future<void> afterUpdate() async {
    _callObservers((observer) => observer.updated(model));
    _callObservers((observer) => observer.saved(model));
    await dispatch(ModelUpdated(model as T));
    await _dispatchCustomEvent('updated');
    await _dispatchCustomEvent('saved');
  }

  Future<bool> beforeDelete() async {
    final allowed =
        _callCancelableObservers((observer) => observer.deleting(model));
    if (!allowed) return false;

    final event = ModelDeleting(model as T);
    await dispatch(event);

    if (event.isPropagationStopped) return false;

    return _dispatchCustomEvent('deleting');
  }

  Future<void> afterDelete() async {
    _callObservers((observer) => observer.deleted(model));
    await dispatch(ModelDeleted(model as T));
    await _dispatchCustomEvent('deleted');
  }

  /// Observer hook for restoring soft-deleted models
  Future<bool> beforeRestore() async {
    final allowed = _callCancelableObservers((observer) => observer.restoring(model));
    if (!allowed) return false;

    final event = ModelRestoring(model as T);
    await dispatch(event);

    if (event.isPropagationStopped) return false;

    return _dispatchCustomEvent('restoring');
  }

  Future<void> afterRestore() async {
    _callObservers((observer) => observer.restored(model));
    await dispatch(ModelRestored(model as T));
    await _dispatchCustomEvent('restored');
  }

  /// Observer hook for force deleting soft-deleted models
  Future<bool> beforeForceDelete() async {
    final allowed = _callCancelableObservers(
      (observer) => observer.forceDeleting(model),
    );
    if (!allowed) return false;

    final event = ModelForceDeleting(model as T);
    await dispatch(event);

    if (event.isPropagationStopped) return false;

    return _dispatchCustomEvent('forceDeleting');
  }

  Future<void> afterForceDelete() async {
    _callObservers((observer) => observer.forceDeleted(model));
    await dispatch(ModelForceDeleted(model as T));
    await _dispatchCustomEvent('forceDeleted');
  }

  /// Observer hook for retrieving models
  Future<void> afterRetrieve() async {
    _callObservers((observer) => observer.retrieved(model));
    await dispatch(ModelRetrieved(model as T));
    await _dispatchCustomEvent('retrieved');
  }
}
