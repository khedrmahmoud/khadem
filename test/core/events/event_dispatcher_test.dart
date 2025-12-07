import 'package:test/test.dart';
import 'package:khadem/src/core/events/event_dispatcher.dart';
import 'package:khadem/src/core/container/service_container.dart';
import 'package:khadem/src/contracts/events/event.dart';
import 'package:khadem/src/contracts/events/listener.dart';
import 'package:khadem/src/contracts/events/subscriber.dart';
import 'package:khadem/src/contracts/events/dispatcher.dart';
import 'package:khadem/src/core/queue/queue_manager.dart';
import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/core/events/call_queued_listener.dart';
import 'package:khadem/src/core/queue/registry/queue_driver_registry.dart';

class TestEvent extends Event {}

class StoppableTestEvent extends StoppableEvent {}

class TestListener extends Listener<TestEvent> {
  bool handled = false;
  @override
  void handle(TestEvent event) {
    handled = true;
  }
}

class QueueableTestListener extends Listener<TestEvent> implements ShouldQueue {
  bool handled = false;
  @override
  void handle(TestEvent event) {
    handled = true;
  }

  @override
  String? get connection => null;

  @override
  String? get queue => null;

  @override
  int? get delay => null;
}

class MockQueueDriver implements QueueDriver {
  final List<QueueJob> pushedJobs = [];

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    pushedJobs.add(job);
  }

  @override
  Future<void> process() async {}
}

class MockConfig implements ConfigInterface {
  @override
  T? get<T>(String key, [T? defaultValue]) => defaultValue;
  @override
  bool has(String key) => false;
  @override
  void set(String key, dynamic value) {}
  @override
  Map<String, dynamic> all() => {};
  @override
  void loadFromRegistry(Map<String, Map<String, dynamic>> registry) {}
  @override
  void reload() {}
  @override
  Map<String, dynamic> section(String key) => {};
}

class TestSubscriber implements Subscriber {
  bool subscribed = false;
  @override
  void subscribe(Dispatcher dispatcher) {
    subscribed = true;
    dispatcher.listen<TestEvent>((e) {});
  }
}

void main() {
  late ServiceContainer container;
  late EventDispatcher dispatcher;
  late MockQueueDriver queueDriver;

  setUp(() {
    container = ServiceContainer();
    queueDriver = MockQueueDriver();
    
    container.singleton<ConfigInterface>((c) => MockConfig());
    
    final registry = QueueDriverRegistry();
    registry.registerDriver('mock', queueDriver);
    registry.setDefaultDriver('mock');

    final queueManager = QueueManager(
      container.resolve<ConfigInterface>(), 
      registry: registry
    );
    container.instance<QueueManager>(queueManager);
    
    dispatcher = EventDispatcher(container);
  });

  test('dispatches to closure', () async {
    bool handled = false;
    dispatcher.listen<TestEvent>((e) => handled = true);
    await dispatcher.dispatch(TestEvent());
    expect(handled, isTrue);
  });

  test('dispatches to listener instance', () async {
    final listener = TestListener();
    dispatcher.listen<TestEvent>(listener);
    await dispatcher.dispatch(TestEvent());
    expect(listener.handled, isTrue);
  });

  test('dispatches to listener type', () async {
    final listener = TestListener();
    container.instance<TestListener>(listener);
    
    dispatcher.listen<TestEvent>(TestListener);
    await dispatcher.dispatch(TestEvent());
    expect(listener.handled, isTrue);
  });

  test('stops propagation', () async {
    bool firstHandled = false;
    bool secondHandled = false;

    dispatcher.listen<StoppableTestEvent>((e) {
      firstHandled = true;
      e.stopPropagation();
    });

    dispatcher.listen<StoppableTestEvent>((e) {
      secondHandled = true;
    });

    await dispatcher.dispatch(StoppableTestEvent());
    expect(firstHandled, isTrue);
    expect(secondHandled, isFalse);
  });

  test('dispatches to queue', () async {
    final listener = QueueableTestListener();
    container.instance<QueueableTestListener>(listener);
    
    dispatcher.listen<TestEvent>(QueueableTestListener);
    await dispatcher.dispatch(TestEvent());
    
    expect(queueDriver.pushedJobs, hasLength(1));
    expect(queueDriver.pushedJobs.first, isA<CallQueuedListener>());
  });

  test('subscribes subscriber', () async {
    final subscriber = TestSubscriber();
    dispatcher.subscribe(subscriber);
    expect(subscriber.subscribed, isTrue);
  });
}
