import '../../model_base/khadem_model.dart';
import 'model_observer.dart';

/// Registry for model observers.
///
/// This class manages the registration and retrieval of observers for models.
class ObserverRegistry {
  static final ObserverRegistry _instance = ObserverRegistry._internal();

  /// Get the singleton instance of the registry.
  static ObserverRegistry get instance => _instance;

  factory ObserverRegistry() => _instance;
  ObserverRegistry._internal();

  /// Map of model type to list of observers
  final Map<Type, List<ModelObserver>> _observers = {};

  /// Register an observer for a model type.
  ///
  /// Example:
  /// ```dart
  /// ObserverRegistry().register<User>(UserObserver());
  /// ```
  void register<T extends KhademModel<T>>(ModelObserver<T> observer) {
    final modelType = T;
    if (!_observers.containsKey(modelType)) {
      _observers[modelType] = [];
    }
    _observers[modelType]!.add(observer);
  }

  /// Get all observers for a model type.
  ///
  /// Returns an empty list if no observers are registered.
  List<ModelObserver<T>> getObservers<T extends KhademModel<T>>() {
    final modelType = T;
    if (!_observers.containsKey(modelType)) {
      return [];
    }
    return _observers[modelType]!.cast<ModelObserver<T>>();
  }

  /// Clear all observers for a model type.
  ///
  /// Useful for testing.
  void clear<T extends KhademModel<T>>() {
    _observers.remove(T);
  }

  /// Clear all registered observers.
  ///
  /// Useful for testing.
  void clearAll() {
    _observers.clear();
  }

  /// Get observers for a specific runtime type.
  ///
  /// This is used internally by EventModel to retrieve observers
  /// based on the model's runtime type.
  List<ModelObserver> getObserversByType(Type modelType) {
    return _observers[modelType] ?? [];
  }

  /// Check if a model type has any observers.
  bool hasObservers<T extends KhademModel<T>>() {
    return _observers.containsKey(T) && _observers[T]!.isNotEmpty;
  }
}
