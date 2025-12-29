class SocketConfig {
  final int port;
  final String? host;
  final Duration? pingInterval;
  final int? maxMessageBytes;
  final bool shared;

  const SocketConfig({
    required this.port,
    this.host,
    this.pingInterval,
    this.maxMessageBytes,
    this.shared = true,
  });
}
