# WebSocket Authorization and Events

This document explains how to implement authorization, middleware, and connection events in Khadem's WebSocket server.

## Authorization

### Connection-Time Authorization

You can authorize clients during the WebSocket upgrade process using headers:

```dart
final server = SocketServer(8080);

// Authorize based on headers during connection
server.useAuth((HttpRequest request) async {
  final authHeader = request.headers['authorization']?.first;
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return false;
  }

  final token = authHeader.substring(7);
  return await validateToken(token);
});

await server.start();
```

### Persistent Authorization State

Once authorized, the client remains authorized throughout the connection:

```dart
server.onConnect((SocketClient client) async {
  if (client.isAuthorized) {
    // Client is authorized for the entire session
    final user = await getUserFromToken(client.authToken!);
    client.set('user', user);
  }
});
```

## Connection Events

### On Connect

Called when a client successfully connects:

```dart
server.onConnect((SocketClient client) async {
  Khadem.logger.info('Client ${client.id} connected');

  // Store user data
  final user = await getUser(client.authToken);
  client.set('user', user);

  // Join user-specific room
  client.joinRoom('user_${user['id']}');

  // Send welcome message
  client.send('welcome', {'user': user['name']});
});
```

### On Disconnect

Called when a client disconnects:

```dart
server.onDisconnect((SocketClient client) {
  Khadem.logger.info('Client ${client.id} disconnected');

  // Clean up resources
  final user = client.get('user');
  if (user != null) {
    cleanupUserSession(user['id']);
  }
});
```

## Middleware

### Global Middleware

Applied to all events:

```dart
server.useMiddleware(AuthMiddleware());
server.useMiddleware(RateLimitMiddleware(100, Duration(minutes: 1)));
```

### Connection Middleware

Executed during WebSocket upgrade:

```dart
server.useMiddleware(SocketMiddleware.connection(
  (HttpRequest request, SocketNextFunction next) async {
    // Log connection attempts
    Khadem.logger.info('Connection from ${request.connectionInfo?.remoteAddress.address}');
    await next();
  },
  name: 'connection-logger',
));
```

### Disconnect Middleware

Executed when clients disconnect:

```dart
server.useMiddleware(SocketMiddleware.disconnect(
  (SocketClient client, SocketNextFunction next) async {
    // Log disconnections
    Khadem.logger.info('Client ${client.id} disconnected');
    await next();
  },
  name: 'disconnect-logger',
));
```

### Room Middleware

Executed when clients join/leave rooms:

```dart
server.useMiddleware(SocketMiddleware.room(
  (SocketClient client, String room, SocketNextFunction next) async {
    // Log room access
    Khadem.logger.info('Client ${client.id} accessing room: $room');
    await next();
  },
  name: 'room-access-logger',
));
```

### Event-Specific Middleware

Applied only to specific events:

```dart
server.on('send_message', handler, middlewares: [
  PermissionMiddleware('send_messages'),
  ValidationMiddleware(
    (data) => data.containsKey('message'),
    errorMessage: 'Message is required'
  ),
]);
```

### Room-Specific Middleware

Applied to events in specific rooms:

```dart
server.useRoom('admin', [
  PermissionMiddleware('admin_access'),
]);
```

## Custom Middleware Classes

Create reusable middleware classes:

```dart
/// Middleware to log all messages
class LoggingMiddleware extends SocketMiddleware {
  LoggingMiddleware()
      : super.message(
          _handleLogging,
          priority: SocketMiddlewarePriority.global,
          name: 'logging-middleware',
        );

  static FutureOr<void> _handleLogging(
    SocketClient client,
    dynamic message,
    SocketNextFunction next,
  ) async {
    Khadem.logger.info('📨 Message from ${client.id}: $message');
    await next();
  }
}

/// Middleware to collect metrics
class MetricsMiddleware extends SocketMiddleware {
  final Map<String, int> _metrics = {};

  MetricsMiddleware()
      : super.message(
          _handleMetrics,
          priority: SocketMiddlewarePriority.terminating,
          name: 'metrics-middleware',
        );

  static FutureOr<void> _handleMetrics(
    SocketClient client,
    dynamic message,
    SocketNextFunction next,
  ) async {
    // Count messages by type
    final messageType = message is Map ? message['type'] ?? 'unknown' : 'unknown';
    final middleware = message as MetricsMiddleware;
    middleware._metrics[messageType] = (middleware._metrics[messageType] ?? 0) + 1;

    // Log metrics every 100 messages
    final totalMessages = middleware._metrics.values.reduce((a, b) => a + b);
    if (totalMessages % 100 == 0) {
      Khadem.logger.info('📊 Message metrics: ${middleware._metrics}');
    }

    await next();
  }
}
```

## Built-in Middleware

### AuthMiddleware

Ensures client is authorized:

```dart
server.useMiddleware(AuthMiddleware());
```

### PermissionMiddleware

Checks for specific permissions:

```dart
PermissionMiddleware('send_messages')
```

### RateLimitMiddleware

Limits request frequency:

```dart
RateLimitMiddleware(100, Duration(minutes: 1)) // 100 requests per minute
```

### ValidationMiddleware

Validates message structure:

```dart
ValidationMiddleware(
  (data) => data is Map && data.containsKey('message'),
  errorMessage: 'Message field is required'
)
```

## Client Context

Store and retrieve data for the client session:

```dart
// Store data
client.set('user', userData);
client.set('preferences', userPrefs);

// Retrieve data
final user = client.get('user');
final prefs = client.get('preferences');
```

## Header Access

Access HTTP headers from the initial request:

```dart
// Get authorization token
final token = client.authToken;

// Get user agent
final userAgent = client.userAgent;

// Get custom headers
final apiKey = client.getHeader('x-api-key');
final allValues = client.getHeaderValues('accept-language');
```

## Complete Example

```dart
void setupWebSocketServer() async {
  final server = SocketServer(8080);

  // Authorization during connection
  server.useAuth((request) async {
    final token = request.headers.header('authorization')?.substring(7);
    return token != null && await validateToken(token);
  });

  // Connection events
  server.onConnect((client) async {
    final user = await getUser(client.authToken!);
    client.set('user', user);
    client.joinRoom('user_${user['id']}');
    client.send('connected', {'user': user});
  });

  server.onDisconnect((client) {
    final user = client.get('user');
    if (user != null) {
      cleanupUserSession(user['id']);
    }
  });

  // Global middleware
  server.useMiddleware(AuthMiddleware());
  server.useMiddleware(RateLimitMiddleware(100, Duration(minutes: 1)));

  // Custom middleware for connection logging
  server.useMiddleware(SocketMiddleware.connection(
    (HttpRequest request, SocketNextFunction next) async {
      Khadem.logger.info('🔗 Connection attempt from ${request.connectionInfo?.remoteAddress.address}');
      await next();
    },
    name: 'connection-logger',
  ));

  // Custom middleware for disconnect logging
  server.useMiddleware(SocketMiddleware.disconnect(
    (SocketClient client, SocketNextFunction next) async {
      Khadem.logger.info('🔌 Client ${client.id} disconnected');
      await next();
    },
    name: 'disconnect-logger',
  ));

  // Custom middleware for room access logging
  server.useMiddleware(SocketMiddleware.room(
    (SocketClient client, String room, SocketNextFunction next) async {
      Khadem.logger.info('🏠 Client ${client.id} accessing room: $room');
      await next();
    },
    name: 'room-access-logger',
  ));

  // Events with middleware
  server.on('send_message', (client, data) async {
    final user = client.get('user');
    server.manager.broadcast(data['room'], 'message', {
      'from': user['id'],
      'message': data['message'],
    });
  }, middlewares: [
    PermissionMiddleware('chat'),
    ValidationMiddleware(
      (data) => data.containsKey('message') && data.containsKey('room')
    ),
  ]);

  // Room-specific middleware
  server.useRoom('admin', [
    PermissionMiddleware('admin_access'),
  ]);

  await server.start();
}
```
