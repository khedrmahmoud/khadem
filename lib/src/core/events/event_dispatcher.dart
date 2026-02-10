import 'dart:async';

import '../../contracts/container/container_interface.dart';
import '../../contracts/events/dispatcher.dart';
import '../../contracts/events/event.dart';
import '../../contracts/events/listener.dart';
import '../../contracts/events/should_broadcast.dart';
import '../../contracts/events/subscriber.dart';
import '../queue/queue_manager.dart';
import '../socket/socket_manager.dart';
import 'call_queued_listener.dart';

/// The default event dispatcher implementation.
///
/// This class manages the registration of event listeners and subscribers,
/// and handles the dispatching of events to those listeners. It supports:
/// - Synchronous listeners
/// - Asynchronous listeners (Future)
/// - Queued listeners (ShouldQueue)
/// - Broadcast events (ShouldBroadcast)
/// - Event propagation stopping (StoppableEvent)
class EventDispatcher implements Dispatcher {
  /// The service container instance.
  final ContainerInterface container;

  /// The registered listeners.
  final Map<Type, List<dynamic>> _listeners = {};

  /// Create a new event dispatcher instance.
  EventDispatcher(this.container);

  @override
  Future<void> dispatch(Event event) async {
    // 1. Handle Broadcasting
    if (event is ShouldBroadcast) {
      await _broadcastEvent(event as ShouldBroadcast);
    }

    // 2. Handle Listeners
    final eventType = event.runtimeType;
    final listeners = _listeners[eventType] ?? [];

    for (final listenerDefinition in listeners) {
      if (event is StoppableEvent && event.isPropagationStopped) {
        break;
      }

      await _dispatchToListener(event, listenerDefinition);
    }
  }

  /// Broadcasts the event using the SocketManager.
  Future<void> _broadcastEvent(ShouldBroadcast event) async {
    try {
      if (container.has<SocketManager>()) {
        final socketManager = container.resolve<SocketManager>();
        final channels = event.broadcastOn();
        final eventName = event.broadcastAs();
        final data = event.broadcastWith();

        for (final channel in channels) {
          // Broadcast to specific room/channel
          socketManager.broadcastToRoom(channel, eventName, data);
        }
      }
    } catch (e) {
      // Log error or handle gracefully. Broadcasting failure shouldn't stop event processing.
      print('Failed to broadcast event ${event.runtimeType}: $e');
    }
  }

  /// Dispatches the event to a specific listener definition.
  Future<void> _dispatchToListener(
    Event event,
    dynamic listenerDefinition,
  ) async {
    dynamic listener;

    if (listenerDefinition is Function) {
      // If it's a closure, execute it.
      final result = listenerDefinition(event);
      if (result is Future) {
        await result;
      }
      return;
    } else if (listenerDefinition is Type) {
      // Resolve listener from container
      listener = container.resolveType(listenerDefinition);
    } else {
      listener = listenerDefinition;
    }

    if (listener is Listener) {
      if (listener is ShouldQueue) {
        await _dispatchToQueue(listener as ShouldQueue, event);
      } else {
        await listener.handle(event);
      }
    }
  }

  Future<void> _dispatchToQueue(ShouldQueue listener, Event event) async {
    final job = CallQueuedListener(
      listener.runtimeType,
      event,
      queue: listener.queue,
    );

    final queueManager = container.resolve<QueueManager>();
    final driver = queueManager.getDriver(listener.connection);

    await driver.push(
      job,
      delay: listener.delay != null ? Duration(seconds: listener.delay!) : null,
    );
  }

  @override
  void listen<T extends Event>(dynamic listener) {
    listenType(T, listener);
  }

  @override
  void listenType(Type eventType, dynamic listener) {
    if (_listeners[eventType] == null) {
      _listeners[eventType] = [];
    }
    _listeners[eventType]!.add(listener);
  }

  @override
  void subscribe(dynamic subscriber) {
    dynamic instance = subscriber;
    if (subscriber is Type) {
      instance = container.resolveType(subscriber);
    }

    if (instance is Subscriber) {
      instance.subscribe(this);
    }
  }

  @override
  void forget(Type eventType) {
    _listeners.remove(eventType);
  }
}
