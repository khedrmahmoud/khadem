import 'dart:async';

import '../../core/socket/socket_client.dart';

typedef SocketEventHandler = FutureOr<void> Function(
  SocketClient client,
  dynamic data,
);
