import 'dart:async';

import 'package:khadem/khadem_dart.dart';
import '../lib/src/core/socket/socket_middlewares.dart' as socket_middlewares;

/// Example of how to set up WebSocket server with authorization
/// 
/// IMPORTANT: Middleware failures now properly prevent actions:
/// - Connection middleware failures prevent WebSocket upgrade
/// - Message middleware failures prevent message processing
/// - Room middleware failures prevent join/leave operations
/// 
/// Test connection middleware failure by adding header: x-test-fail: true
void setupWebSocketServer() async {
  final server = SocketServer(8080);

  // Set up authorization callback - called during WebSocket upgrade
  server.useAuth((Request request) async {
    // Check authorization header
    final authHeader = request.headers.header('authorization') ??
                      request.headers.header('Authorization');

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return false;
    }

    final token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Validate token (implement your own validation logic)
    final isValid = await validateToken(token);
    if (!isValid) {
      return false;
    }

    // You can also check other headers like API keys, etc.
    final apiKey = request.headers.header('x-api-key');
    if (apiKey != null) {
      // Validate API key
      return validateApiKey(apiKey);
    }

    return true;
  });

  // Set up onConnect callback
  server.onConnect((SocketClient client) async {
    Khadem.logger.info('🟢 Client ${client.id} connected');

    // Store user information in client context
    final token = client.authToken;
    if (token != null) {
      final user = await getUserFromToken(token);
      client.set('user', user);

      // Join user-specific room
      client.joinRoom('user_${user['id']}');
    }

    // Send welcome message
    client.send('welcome', {
      'message': 'Connected successfully',
      'user_agent': client.userAgent,
      'authorized': client.isAuthorized,
    });
  });

  // Set up onDisconnect callback
  server.onDisconnect((SocketClient client) {
    Khadem.logger.info('🔴 Client ${client.id} disconnected');

    // Clean up user-specific data
    final user = client.get('user');
    if (user != null) {
      // Perform cleanup operations
      cleanupUserSession(user['id']);
    }
  });

  // Add global middleware for all connections
  server.useMiddleware(socket_middlewares.AuthMiddleware());

  // Add rate limiting
  server.useMiddleware(socket_middlewares.RateLimitMiddleware(100, const Duration(minutes: 1)));

  // Add custom connection middleware
  server.useMiddleware(SocketMiddleware.connection(
    (Request request, SocketNextFunction next) async {
      // Log connection attempts
      Khadem.logger.info('🔗 Connection attempt from ${request.raw.connectionInfo?.remoteAddress.address}');
      await next();
    },
    name: 'connection-logger',
  ),);

  // Add custom disconnect middleware
  server.useMiddleware(SocketMiddleware.disconnect(
    (SocketClient client, SocketNextFunction next) async {
      // Log disconnections
      Khadem.logger.info('🔌 Client ${client.id} disconnected');
      await next();
    },
    name: 'disconnect-logger',
  ),);

  // Add custom room middleware
  server.useMiddleware(SocketMiddleware.room(
    (SocketClient client, String room, SocketNextFunction next) async {
      // Log room joins/leaves
      Khadem.logger.info('🏠 Client ${client.id} accessing room: $room');
      await next();
    },
    name: 'room-access-logger',
  ),);

  // Define events with specific middlewares
  server.on('send_message', (SocketClient client, dynamic data) async {
    // This event requires authentication (via AuthMiddleware)
    final user = client.get('user');
    final message = data['message'];
    final room = data['room'];

    // Broadcast to room
    server.manager.broadcast(room, 'new_message', {
      'from': user['id'],
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }, middlewares: [
    socket_middlewares.PermissionMiddleware('send_messages'),
    socket_middlewares.ValidationMiddleware(
      (data) => data is Map && data.containsKey('message') && data.containsKey('room'),
      errorMessage: 'Message must contain "message" and "room" fields',
    ),
  ],);

  server.on('join_room', (SocketClient client, dynamic data) async {
    final room = data['room'];
    client.joinRoom(room);
    client.send('room_joined', {'room': room});
  }, middlewares: [
    socket_middlewares.ValidationMiddleware(
      (data) => data is Map && data.containsKey('room'),
      errorMessage: 'Must specify room to join',
    ),
  ],);

  server.on('leave_room', (SocketClient client, dynamic data) async {
    final room = data['room'];
    client.leaveRoom(room);
    client.send('room_left', {'room': room});
  });

  // Room-specific middleware
  server.useRoom('admin', [
    socket_middlewares.PermissionMiddleware('admin_access'),
  ],);

  server.on('admin_command', (SocketClient client, dynamic data) async {
    // This will only be accessible to clients in 'admin' room with admin permissions
    final command = data['command'];
    executeAdminCommand(command);
  });

  await server.start();
}

/// Custom middleware examples

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

/// Middleware to handle CORS for WebSocket connections
class CorsMiddleware extends SocketMiddleware {
  CorsMiddleware()
      : super.connection(
          _handleCors,
          priority: SocketMiddlewarePriority.connection,
          name: 'cors-middleware',
        );

  static FutureOr<void> _handleCors(
    Request request,
    SocketNextFunction next,
  ) async {
    // Check origin header
    final origin = request.header('origin');
    if (origin != null) {
      // Add CORS headers if needed
      request.raw.response.headers.set('Access-Control-Allow-Origin', origin);
      request.raw.response.headers.set('Access-Control-Allow-Credentials', 'true');
    }

    // Simulate middleware failure for testing
    final shouldFail = request.header('x-test-fail') == 'true';
    if (shouldFail) {
      throw Exception('Connection middleware failed for testing purposes');
    }

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

/// Example token validation function
Future<bool> validateToken(String token) async {
  // Implement your token validation logic here
  // For example, check against database, verify JWT, etc.
  return token.length > 10; // Simple example
}

/// Example API key validation function
Future<bool> validateApiKey(String apiKey) async {
  // Implement your API key validation logic here
  return apiKey.startsWith('api_');
}

/// Example user retrieval from token
Future<Map<String, dynamic>> getUserFromToken(String token) async {
  // Implement your user retrieval logic here
  return {
    'id': 123,
    'name': 'John Doe',
    'permissions': ['send_messages', 'join_rooms'],
  };
}

/// Example cleanup function
void cleanupUserSession(int userId) {
  // Implement cleanup logic here
  // For example, remove from online users list, save last seen time, etc.
}

/// Example admin command execution
void executeAdminCommand(String command) {
  // Implement admin command logic here
}
