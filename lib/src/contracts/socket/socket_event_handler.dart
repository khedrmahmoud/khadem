import 'dart:async';

import '../../core/socket/socket_context.dart';

typedef SocketEventHandler = FutureOr<void> Function(
  SocketContext context,
);
