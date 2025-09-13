import 'dart:io';

import 'package:khadem/src/core/socket/socket_client.dart';
import 'package:khadem/src/core/socket/socket_manager.dart';
import 'package:test/test.dart';

// Simple mock classes for testing
class TestSocketClient implements SocketClient {
  final String _id;
  final Map<String, dynamic> _context = {};
  final Set<String> _rooms = {};
  final List<Map<String, dynamic>> sentMessages = [];

  TestSocketClient(this._id);

  @override
  String get id => _id;

  @override
  Set<String> get rooms => _rooms;

  @override
  SocketManager get manager => throw UnimplementedError();

  @override
  WebSocket get socket => throw UnimplementedError();

  @override
  void send(String event, dynamic data) {
    sentMessages.add({'event': event, 'data': data});
  }

  @override
  dynamic get(String key) => _context[key];

  @override
  void set(String key, dynamic value) => _context[key] = value;

  @override
  void close([int code = 1000, String reason = '']) {
    // Mock implementation
  }

  @override
  void joinRoom(String room) {
    _rooms.add(room);
  }

  @override
  void leaveRoom(String room) {
    _rooms.remove(room);
  }

  @override
  bool isInRoom(String room) => _rooms.contains(room);
  
  @override
  // TODO: implement authToken
  String? get authToken => throw UnimplementedError();
  
  @override
  String? getHeader(String name) {
    // TODO: implement getHeader
    throw UnimplementedError();
  }
  
  @override
  List<String>? getHeaderValues(String name) {
    // TODO: implement getHeaderValues
    throw UnimplementedError();
  }
  
  @override
  // TODO: implement headers
  HttpHeaders? get headers => throw UnimplementedError();
  
  @override
  // TODO: implement isAuthenticated
  bool get isAuthenticated => throw UnimplementedError();
  
  @override
  // TODO: implement isAuthorized
  bool get isAuthorized => throw UnimplementedError();
  
  @override
  // TODO: implement user
  Map<String, dynamic>? get user => throw UnimplementedError();
  
  @override
  // TODO: implement userAgent
  String? get userAgent => throw UnimplementedError();
}

void main() {
  group('SocketManager Event Broadcasting', () {
    late SocketManager socketManager;
    late TestSocketClient client1;
    late TestSocketClient client2;
    late TestSocketClient client3;

    setUp(() {
      socketManager = SocketManager();
      client1 = TestSocketClient('client1');
      client2 = TestSocketClient('client2');
      client3 = TestSocketClient('client3');
    });

    test('subscribeToEvent adds client to event subscribers', () {
      socketManager.addClient(client1);
      socketManager.subscribeToEvent('user:login', client1);

      expect(socketManager.isClientSubscribedToEvent('user:login', client1), isTrue);
      expect(socketManager.getEventSubscriberCount('user:login'), equals(1));
    });

    test('unsubscribeFromEvent removes client from event subscribers', () {
      socketManager.addClient(client1);
      socketManager.subscribeToEvent('user:login', client1);
      expect(socketManager.isClientSubscribedToEvent('user:login', client1), isTrue);

      socketManager.unsubscribeFromEvent('user:login', client1);
      expect(socketManager.isClientSubscribedToEvent('user:login', client1), isFalse);
      expect(socketManager.getEventSubscriberCount('user:login'), equals(0));
    });

    test('multiple clients can subscribe to the same event', () {
      socketManager.addClient(client1);
      socketManager.addClient(client2);
      socketManager.addClient(client3);

      socketManager.subscribeToEvent('notification', client1);
      socketManager.subscribeToEvent('notification', client2);
      socketManager.subscribeToEvent('notification', client3);

      expect(socketManager.getEventSubscriberCount('notification'), equals(3));
      expect(socketManager.isClientSubscribedToEvent('notification', client1), isTrue);
      expect(socketManager.isClientSubscribedToEvent('notification', client2), isTrue);
      expect(socketManager.isClientSubscribedToEvent('notification', client3), isTrue);
    });

    test('clients can subscribe to multiple events', () {
      socketManager.addClient(client1);

      socketManager.subscribeToEvent('event1', client1);
      socketManager.subscribeToEvent('event2', client1);
      socketManager.subscribeToEvent('event3', client1);

      final subscriptions = socketManager.getClientSubscriptions(client1);
      expect(subscriptions.length, equals(3));
      expect(subscriptions.contains('event1'), isTrue);
      expect(subscriptions.contains('event2'), isTrue);
      expect(subscriptions.contains('event3'), isTrue);
    });

    test('broadcastToEventSubscribers sends to all subscribers', () {
      socketManager.addClient(client1);
      socketManager.addClient(client2);
      socketManager.addClient(client3);

      socketManager.subscribeToEvent('broadcast:event', client1);
      socketManager.subscribeToEvent('broadcast:event', client2);
      socketManager.subscribeToEvent('other:event', client3);

      socketManager.broadcastToEventSubscribers('broadcast:event', 'test data');

      expect(client1.sentMessages.length, equals(1));
      expect(client1.sentMessages[0]['event'], equals('broadcast:event'));
      expect(client1.sentMessages[0]['data'], equals('test data'));

      expect(client2.sentMessages.length, equals(1));
      expect(client2.sentMessages[0]['event'], equals('broadcast:event'));
      expect(client2.sentMessages[0]['data'], equals('test data'));

      expect(client3.sentMessages.length, equals(0));
    });

    test('broadcastEvent is alias for broadcastToEventSubscribers', () {
      socketManager.addClient(client1);
      socketManager.subscribeToEvent('alias:test', client1);

      socketManager.broadcastEvent('alias:test', 'alias data');

      expect(client1.sentMessages.length, equals(1));
      expect(client1.sentMessages[0]['event'], equals('alias:test'));
      expect(client1.sentMessages[0]['data'], equals('alias data'));
    });

    test('hasEventSubscribers returns true when event has subscribers', () {
      socketManager.addClient(client1);
      socketManager.subscribeToEvent('has:subscribers', client1);

      expect(socketManager.hasEventSubscribers('has:subscribers'), isTrue);
      expect(socketManager.hasEventSubscribers('no:subscribers'), isFalse);
    });

    test('removeClient cleans up event subscriptions', () {
      socketManager.addClient(client1);
      socketManager.addClient(client2);

      socketManager.subscribeToEvent('cleanup:event', client1);
      socketManager.subscribeToEvent('cleanup:event', client2);
      socketManager.subscribeToEvent('other:event', client1);

      expect(socketManager.getEventSubscriberCount('cleanup:event'), equals(2));
      expect(socketManager.getEventSubscriberCount('other:event'), equals(1));

      socketManager.removeClient(client1);

      expect(socketManager.getEventSubscriberCount('cleanup:event'), equals(1));
      expect(socketManager.getEventSubscriberCount('other:event'), equals(0));
      expect(socketManager.isClientSubscribedToEvent('cleanup:event', client1), isFalse);
      expect(socketManager.isClientSubscribedToEvent('other:event', client1), isFalse);
    });

    test('broadcastToEventSubscribers does nothing for event with no subscribers', () {
      socketManager.addClient(client1);
      socketManager.subscribeToEvent('subscribed:event', client1);

      // This should not throw or cause issues
      socketManager.broadcastToEventSubscribers('unsubscribed:event', 'data');
    });

    test('event subscribers are cleaned up when last subscriber is removed', () {
      socketManager.addClient(client1);
      socketManager.addClient(client2);

      socketManager.subscribeToEvent('cleanup:test', client1);
      socketManager.subscribeToEvent('cleanup:test', client2);

      expect(socketManager.hasEventSubscribers('cleanup:test'), isTrue);

      socketManager.unsubscribeFromEvent('cleanup:test', client1);
      expect(socketManager.hasEventSubscribers('cleanup:test'), isTrue);

      socketManager.unsubscribeFromEvent('cleanup:test', client2);
      expect(socketManager.hasEventSubscribers('cleanup:test'), isFalse);
    });
  });
}
