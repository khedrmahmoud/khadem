import '../../../../contracts/events/event.dart';
import '../../orm/model_events.dart';
import '../../orm/observers/model_observer.dart';
import '../../orm/observers/observer_registry.dart';
import '../../../../application/khadem.dart';
import '../khadem_model.dart';

mixin HasEvents<T> on KhademModel<T> {
  /// The event map for the model.
  Map<String, Event Function(T)> get dispatchesEvents => {};

  /// Register an observer for this model type.
  static void observe<T extends KhademModel<T>>(ModelObserver<T> observer) {
    ObserverRegistry().register<T>(observer);
  }

  /// Dispatch a custom event.
  Future<void> _dispatchCustomEvent(String lifecycle) async {
    if (dispatchesEvents.containsKey(lifecycle)) {
      final eventBuilder = dispatchesEvents[lifecycle];
      if (eventBuilder != null) {
        final event = eventBuilder(this as T);
        await Khadem.events.dispatch(event);
      }
    }
  }

  /// Fire a model lifecycle event.
  Future<bool> fireModelEvent(String event, {bool halt = true}) async {
    // 1. Call Observers
    final observers = ObserverRegistry().getObserversByType(runtimeType);
    for (final observer in observers) {
      bool? result;
      switch (event) {
        case 'creating': result = observer.creating(this); break;
        case 'created': observer.created(this); break;
        case 'updating': result = observer.updating(this); break;
        case 'updated': observer.updated(this); break;
        case 'saving': result = observer.saving(this); break;
        case 'saved': observer.saved(this); break;
        case 'deleting': result = observer.deleting(this); break;
        case 'deleted': observer.deleted(this); break;
        case 'restoring': result = observer.restoring(this); break;
        case 'restored': observer.restored(this); break;
        case 'forceDeleting': result = observer.forceDeleting(this); break;
        case 'forceDeleted': observer.forceDeleted(this); break;
        case 'retrieved': observer.retrieved(this); break;
      }
      
      if (halt && result == false) return false;
    }

    // 2. Dispatch System Events
    Event? systemEvent;
    switch (event) {
      case 'creating': systemEvent = ModelCreating(this as T); break;
      case 'created': systemEvent = ModelCreated(this as T); break;
      case 'updating': systemEvent = ModelUpdating(this as T); break;
      case 'updated': systemEvent = ModelUpdated(this as T); break;
      case 'deleting': systemEvent = ModelDeleting(this as T); break;
      case 'deleted': systemEvent = ModelDeleted(this as T); break;
      // ... others
    }

    if (systemEvent != null) {
      await Khadem.events.dispatch(systemEvent);
      if (halt && systemEvent is StoppableEvent && systemEvent.isPropagationStopped) {
        return false;
      }
    }

    // 3. Dispatch Custom Events
    await _dispatchCustomEvent(event);

    return true;
  }
}
