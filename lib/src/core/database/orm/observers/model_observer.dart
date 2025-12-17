import '../../model_base/khadem_model.dart';

/// Base class for model observers.
abstract class ModelObserver<T extends KhademModel<T>> {
  dynamic creating(T model) {}
  void created(T model) {}
  dynamic updating(T model) {}
  void updated(T model) {}
  dynamic saving(T model) {}
  void saved(T model) {}
  dynamic deleting(T model) => true;
  void deleted(T model) {}
  void retrieving(T model) {}
  void retrieved(T model) {}
  dynamic restoring(T model) => true;
  void restored(T model) {}
  dynamic forceDeleting(T model) => true;
  void forceDeleted(T model) {}
}
