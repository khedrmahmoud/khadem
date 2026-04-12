import 'dart:convert';

import 'package:khadem/src/support/exceptions/payload_too_large_exception.dart';

class SocketPacket {
  final String event;
  final dynamic data;
  final String? id;
  final String? namespace;

  const SocketPacket({required this.event, this.data, this.id, this.namespace});

  factory SocketPacket.fromMap(Map<String, dynamic> map) {
    final event = map['event'];
    if (event is! String || event.isEmpty) {
      throw const FormatException('Invalid packet: missing event');
    }

    return SocketPacket(
      event: event,
      data: map['data'],
      id: map['id']?.toString(),
      namespace: map['namespace'] ?? _parseNamespace(event),
    );
  }

  static String? _parseNamespace(String event) {
    final index = event.indexOf(':');
    return index > 0 ? event.substring(0, index) : null;
  }

  static SocketPacket parse(dynamic raw, {int? maxMessageBytes}) {
    String text;
    if (raw is String) {
      text = raw;
    } else if (raw is List<int>) {
      text = utf8.decode(raw);
    } else {
      throw const FormatException('Unsupported message type');
    }

    if (maxMessageBytes != null && text.length > maxMessageBytes) {
      throw PayloadTooLargeException('Message too large');
    }

    try {
      final map = jsonDecode(text);
      if (map is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON object');
      }
      return SocketPacket.fromMap(map);
    } catch (e) {
      if (e is FormatException || e is PayloadTooLargeException) rethrow;
      throw const FormatException('Invalid packet format');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      if (data != null) 'data': data,
      if (id != null) 'id': id,
      if (namespace != null) 'namespace': namespace,
    };
  }

  String toJson() => jsonEncode(toMap(), toEncodable: _defaultToEncodable);

  dynamic _defaultToEncodable(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Uri) return value.toString();
    if (value is Enum) return value.name;
    final toJson = _tryToJson(value);
    if (toJson != null) return toJson;
    // Fallback to string to avoid encoder failures (e.g., database exceptions).
    return value.toString();
  }

  dynamic _tryToJson(Object value) {
    try {
      final toJson = (value as dynamic).toJson;
      if (toJson is Function) {
        return toJson();
      }
    } catch (_) {
      // ignore – fallback will handle it
    }
    return null;
  }
}
