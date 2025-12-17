import '../../../../application/khadem.dart';
import '../../../../contracts/events/event.dart';
import '../../orm/model_events.dart';
import '../../orm/observers/model_observer.dart';
import '../../orm/observers/observer_registry.dart';
import '../khadem_model.dart';

mixin HasEvents<T> {
  /// The event map for the model.
  Map<ModelLifecycle, Event Function(T)> get dispatchesEvents => {};

  /// Register an observer for this model type.
  static void observe<T extends KhademModel<T>>(ModelObserver<T> observer) {
    ObserverRegistry().register<T>(observer);
  }

  /// Dispatch a custom event.
  Future<void> _dispatchCustomEvent(ModelLifecycle lifecycle) async {
    if (dispatchesEvents.containsKey(lifecycle)) {
      final eventBuilder = dispatchesEvents[lifecycle];
      if (eventBuilder != null) {
        final event = eventBuilder(this as dynamic);
        await Khadem.events.dispatch(event);
      }
    }
  }

  /// Fire a model lifecycle event.
  Future<bool> fireModelEvent(ModelLifecycle event, {bool halt = true}) async {
    // 1. Call Observers
    final observers = ObserverRegistry().getObserversByType(runtimeType);
    for (final observer in observers) {
      bool? result;
      switch (event) {
        case ModelLifecycle.creating:
          result = observer.creating(this as dynamic);
          break;
        case ModelLifecycle.created:
          observer.created(this as dynamic);
          break;
        case ModelLifecycle.updating:
          result = observer.updating(this as dynamic);
          break;
        case ModelLifecycle.updated:
          observer.updated(this as dynamic);
          break;
        case ModelLifecycle.saving:
          result = observer.saving(this as dynamic);
          break;
        case ModelLifecycle.saved:
          observer.saved(this as dynamic);
          break;
        case ModelLifecycle.deleting:
          result = observer.deleting(this as dynamic);
          break;
        case ModelLifecycle.deleted:
          observer.deleted(this as dynamic);
          break;
        case ModelLifecycle.restoring:
          result = observer.restoring(this as dynamic);
          break;
        case ModelLifecycle.restored:
          observer.restored(this as dynamic);
          break;
        case ModelLifecycle.forceDeleting:
          result = observer.forceDeleting(this as dynamic);
          break;
        case ModelLifecycle.forceDeleted:
          observer.forceDeleted(this as dynamic);
          break;
        case ModelLifecycle.retrieved:
          observer.retrieved(this as dynamic);
          break;
      }

      if (halt && result == false) return false;
    }

    // 2. Dispatch System Events
    Event? systemEvent;
    switch (event) {
      case ModelLifecycle.creating:
        systemEvent = ModelCreating(this as dynamic);
        break;
      case ModelLifecycle.created:
        systemEvent = ModelCreated(this as dynamic);
        break;
      case ModelLifecycle.updating:
        systemEvent = ModelUpdating(this as dynamic);
        break;
      case ModelLifecycle.updated:
        systemEvent = ModelUpdated(this as dynamic);
        break;
      case ModelLifecycle.deleting:
        systemEvent = ModelDeleting(this as dynamic);
        break;
      case ModelLifecycle.deleted:
        systemEvent = ModelDeleted(this as dynamic);
        break;
      case ModelLifecycle.restoring:
        systemEvent = ModelRestoring(this as dynamic);
        break;
      case ModelLifecycle.restored:
        systemEvent = ModelRestored(this as dynamic);
        break;
      case ModelLifecycle.forceDeleting:
        systemEvent = ModelForceDeleting(this as dynamic);
        break;
      case ModelLifecycle.forceDeleted:
        systemEvent = ModelForceDeleted(this as dynamic);
        break;
      case ModelLifecycle.retrieved:
        systemEvent = ModelRetrieved(this as dynamic);
        break;
      default:
        break;
    }

    if (systemEvent != null) {
      await Khadem.events.dispatch(systemEvent);
      if (halt &&
          systemEvent is StoppableEvent &&
          systemEvent.isPropagationStopped) {
        return false;
      }
    }

    // 3. Dispatch Custom Events
    await _dispatchCustomEvent(event);

    return true;
  }
}
