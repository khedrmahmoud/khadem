class ParsedHttpRequest {
  final String method;
  final String path;
  final Map<String, String> headers;
  final String body;

  ParsedHttpRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.body,
  });
}

class HttpRequestParser {
  static ParsedHttpRequest parse(String raw) {
    final lines = raw.split('\r\n');
    final requestLine = lines.first.split(' ');
    final method = requestLine[0];
    final path = requestLine[1];

    final headers = <String, String>{};
    int i = 1;
    while (i < lines.length && lines[i].isNotEmpty) {
      final parts = lines[i].split(':');
      if (parts.length >= 2) {
        headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
      i++;
    }

    final body = lines.skip(i + 1).join('\n');

    return ParsedHttpRequest(
      method: method,
      path: path,
      headers: headers,
      body: body,
    );
  }
}
