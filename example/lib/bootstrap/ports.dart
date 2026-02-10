import 'package:khadem/khadem.dart' show Khadem;

int resolveHttpPort(List<String> args) {
  return _readIntArg(args, 'port') ??
      Khadem.config.get('app.http_port') ??
      9000;
}

int resolveSocketPort(List<String> args) {
  return _readIntArg(args, 'socket-port') ??
      Khadem.config.get('app.socket_port') ??
      8080;
}

int? _readIntArg(List<String> args, String name) {
  final flag = '--$name';

  for (var i = 0; i < args.length; i++) {
    final current = args[i];

    if (current == flag && i + 1 < args.length) {
      return int.tryParse(args[i + 1]);
    }

    if (current.startsWith('$flag=')) {
      return int.tryParse(current.substring(flag.length + 1));
    }
  }

  return null;
}
