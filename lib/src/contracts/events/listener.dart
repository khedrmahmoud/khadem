import 'dart:async';
import 'event.dart';

/// Base class for event listeners.
///
/// Listeners are responsible for handling specific events.
///
/// [T] is the type of event this listener handles.
abstract class Listener<T extends Event> {
  /// Handle the event.
  FutureOr<void> handle(T event);

  /// Handle the event failure.
  ///
  /// This method is called if the [handle] method throws an exception.
  FutureOr<void> failed(T event, Object error, StackTrace stackTrace) {}
}

/// Interface for listeners that should be executed in the background queue.
abstract class ShouldQueue {
  /// The name of the connection the job should be sent to.
  String? get connection => null;

  /// The name of the queue the job should be sent to.
  String? get queue => null;

  /// The number of seconds before the job should be processed.
  int? get delay => null;
}
