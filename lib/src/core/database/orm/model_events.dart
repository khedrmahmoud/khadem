import '../../../contracts/events/event.dart';

/// Base class for all model lifecycle events.
abstract class ModelLifecycleEvent<T> extends Event {
  final T model;
  ModelLifecycleEvent(this.model);
}

/// Event fired before a model is created.
class ModelCreating<T> extends ModelLifecycleEvent<T>
    implements StoppableEvent {
  ModelCreating(super.model);

  bool _isPropagationStopped = false;

  @override
  bool get isPropagationStopped => _isPropagationStopped;

  @override
  void stopPropagation() {
    _isPropagationStopped = true;
  }
}

/// Event fired after a model is created.
class ModelCreated<T> extends ModelLifecycleEvent<T> {
  ModelCreated(super.model);
}

/// Event fired before a model is updated.
class ModelUpdating<T> extends ModelLifecycleEvent<T>
    implements StoppableEvent {
  ModelUpdating(super.model);

  bool _isPropagationStopped = false;

  @override
  bool get isPropagationStopped => _isPropagationStopped;

  @override
  void stopPropagation() {
    _isPropagationStopped = true;
  }
}

/// Event fired after a model is updated.
class ModelUpdated<T> extends ModelLifecycleEvent<T> {
  ModelUpdated(super.model);
}

/// Event fired before a model is deleted.
class ModelDeleting<T> extends ModelLifecycleEvent<T>
    implements StoppableEvent {
  ModelDeleting(super.model);

  bool _isPropagationStopped = false;

  @override
  bool get isPropagationStopped => _isPropagationStopped;

  @override
  void stopPropagation() {
    _isPropagationStopped = true;
  }
}

/// Event fired after a model is deleted.
class ModelDeleted<T> extends ModelLifecycleEvent<T> {
  ModelDeleted(super.model);
}

/// Event fired before a model is restored.
class ModelRestoring<T> extends ModelLifecycleEvent<T>
    implements StoppableEvent {
  ModelRestoring(super.model);

  bool _isPropagationStopped = false;

  @override
  bool get isPropagationStopped => _isPropagationStopped;

  @override
  void stopPropagation() {
    _isPropagationStopped = true;
  }
}

/// Event fired after a model is restored.
class ModelRestored<T> extends ModelLifecycleEvent<T> {
  ModelRestored(super.model);
}

/// Event fired before a model is force deleted.
class ModelForceDeleting<T> extends ModelLifecycleEvent<T>
    implements StoppableEvent {
  ModelForceDeleting(super.model);

  bool _isPropagationStopped = false;

  @override
  bool get isPropagationStopped => _isPropagationStopped;

  @override
  void stopPropagation() {
    _isPropagationStopped = true;
  }
}

/// Event fired after a model is force deleted.
class ModelForceDeleted<T> extends ModelLifecycleEvent<T> {
  ModelForceDeleted(super.model);
}

/// Event fired after a model is retrieved.
class ModelRetrieved<T> extends ModelLifecycleEvent<T> {
  ModelRetrieved(super.model);
}
