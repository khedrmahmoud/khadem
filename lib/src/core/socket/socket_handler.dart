import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/contracts/exceptions/exception_handler_contract.dart';
import 'package:khadem/src/support/exceptions/not_found_exception.dart';
import 'package:khadem/src/support/helpers/container_helper.dart';

import 'channel/socket_channel.dart';
import 'routing/socket_router.dart';
import 'socket_client.dart';
import 'socket_context.dart';
import 'socket_manager.dart';
import 'socket_packet.dart';

class SocketHandler {
  final SocketClient _client;
  final SocketManager _manager;
  final SocketRouter _router;
  final ExceptionHandlerContract _exceptionHandler;
  final int? _maxMessageBytes;

  SocketHandler({
    required SocketClient client,
    required SocketManager manager,
    required SocketRouter router,
    int? maxMessageBytes,
  })  : _client = client,
        _manager = manager,
        _router = router,
        _exceptionHandler = resolve<ExceptionHandlerContract>(),
        _maxMessageBytes = maxMessageBytes;

  void init() {
    _client.socket.listen(
      _onData,
      onDone: _onDone,
      onError: (Object error, StackTrace stackTrace) {
        _handleError(error, stackTrace);
        _manager.removeClient(_client);
      },
    );
  }

  Future<void> _onData(dynamic raw) async {
    SocketPacket? packet;
    try {
      packet = SocketPacket.parse(raw, maxMessageBytes: _maxMessageBytes);
      await _handlePacket(packet);
    } catch (e, s) {
      await _handleError(e, s, packet);
    }
  }

  Future<void> _handlePacket(SocketPacket packet) async {
    final context = SocketContext(client: _client, packet: packet);

    // Determine channel: prefer packet namespace, fallback to connection path
    final channelName = packet.namespace;
    SocketChannel? channel;

    if (channelName != null && channelName.isNotEmpty) {
      channel = _router.match(channelName);
    } else {
      // If no namespace in packet, try the connection path
      // Note: path usually starts with /
      channel = _router.match(_client.handshakeRequest.path);
    }

    if (channel == null) {
      throw NotFoundException('Channel not found');
    }

    final handlerEntry = channel.getEntry(packet.event);

    if (handlerEntry == null) {
      throw NotFoundException('Event not registered: ${packet.event}');
    }

    await context.run(() async {
      await handlerEntry.handler(context);
      if (packet.id != null) {
        _client.ack(packet.id!, event: packet.event);
      }
    });
  }

  Future<void> _handleError(
    Object error, [
    StackTrace? stackTrace,
    SocketPacket? packet,
  ]) async {
    final result = await _exceptionHandler.handle(error, stackTrace);

    final details = <String, dynamic>{
      if (result.details != null) ...result.details!,
      if (result.stackTrace != null)
        'stack_trace': result.stackTrace.toString(),
    };

    // Add socket-specific context if in development
    if (Khadem.isDevelopment) {
      details.addAll({
        'type': error.runtimeType.toString(),
        'client': {
          'id': _client.id,
          'rooms': _client.rooms.toList(),
          'channel': packet?.namespace ?? _client.handshakeRequest.path,
        },
        if (packet != null)
          'packet': {
            'id': packet.id,
            'event': packet.event,
            'namespace': packet.namespace,
          },
      });
    }

    _client.sendError(
      id: packet?.id,
      event: packet?.event,
      status: result.statusCode,
      message:
          result.message ?? 'An error occurred while processing your request',
      details: details.isNotEmpty ? details : null,
    );
  }

  void _onDone() {
    _manager.removeClient(_client);
  }
}
