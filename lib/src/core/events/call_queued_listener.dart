import '../../application/khadem.dart';
import '../../contracts/events/event.dart';
import '../../contracts/events/listener.dart';
import '../../contracts/queue/queue_job.dart';

/// A queue job that executes a specific listener for an event.
///
/// This job is automatically created and dispatched by the [EventDispatcher]
/// when a listener implements the [ShouldQueue] interface.
class CallQueuedListener extends QueueJob {
  /// The type of the listener to resolve and execute.
  final Type listenerType;

  /// The event payload to pass to the listener.
  final Event event;

  /// The specific queue to dispatch this job to (optional).
  final String? _queue;

  /// Create a new queued listener job.
  CallQueuedListener(this.listenerType, this.event, {String? queue})
      : _queue = queue;

  @override
  String get queue => _queue ?? super.queue;

  @override
  Future<void> handle() async {
    final container = Khadem.container;
    final listener = container.resolveType(listenerType);

    if (listener is Listener) {
      await listener.handle(event);
    }
  }
}
