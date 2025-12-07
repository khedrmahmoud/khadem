import 'dispatcher.dart';

/// Interface for event subscribers.
///
/// Subscribers allow you to group multiple event listeners within a single class.
abstract class Subscriber {
  /// Subscribe to events.
  void subscribe(Dispatcher dispatcher);
}
