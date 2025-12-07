import '../../contracts/container/container_interface.dart';
import '../../contracts/events/dispatcher.dart';
import '../../contracts/provider/service_provider.dart';

/// Service provider for registering event listeners and subscribers.
///
/// Extend this class in your application to map events to their listeners.
///
/// Example:
/// ```dart
/// class AppEventServiceProvider extends EventServiceProvider {
///   @override
///   Map<Type, List<Type>> get listen => {
///     UserCreated: [SendWelcomeEmail],
///   };
///
///   @override
///   List<Type> get subscribe => [
///     UserEventSubscriber,
///   ];
/// }
/// ```
abstract class EventServiceProvider extends ServiceProvider {
  /// The event handler mappings for the application.
  ///
  /// Maps an Event class to a list of Listener classes.
  Map<Type, List<Type>> get listen => {};

  /// The subscriber classes to register.
  List<Type> get subscribe => [];

  @override
  void register(ContainerInterface container) {
    //
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    final dispatcher = container.resolve<Dispatcher>();
    
    // Register mapped listeners
    listen.forEach((event, listeners) {
      for (final listener in listeners) {
        dispatcher.listenType(event, listener);
      }
    });

    // Register subscribers
    for (final subscriberType in subscribe) {
      dispatcher.subscribe(subscriberType);
    }
  }
}
