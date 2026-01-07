import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class FakeHttpRequest extends Stream<Uint8List> implements HttpRequest {
  @override
  String method = 'GET';

  @override
  Uri uri = Uri.parse('/test?param=value');

  @override
  HttpHeaders headers = FakeHttpHeaders();

  @override
  HttpSession session = FakeHttpSession();

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final data = Uint8List.fromList('{"name": "test", "value": 123}'.codeUnits);
    return Stream<Uint8List>.fromIterable([data]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json'],
    'user-agent': ['TestAgent/1.0'],
    'accept': ['application/json'],
  };

  @override
  bool get chunkedTransferEncoding => false;

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _headers[key] ??= [];
    _headers[key]!.add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _headers[key] = [value.toString()];
  }

  @override
  void remove(String name, Object value) {
    final key = name.toLowerCase();
    _headers[key]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  String? value(String name) => _headers[name.toLowerCase()]?.first;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpSession implements HttpSession {
  final Map<String, dynamic> _data = {};

  @override
  String get id => 'test_session_id';

  @override
  bool get isNew => true;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  void operator []=(Object? key, dynamic value) {
    _data[key as String] = value;
  }

  @override
  bool containsKey(Object? key) => _data.containsKey(key);

  @override
  dynamic remove(Object? key) => _data.remove(key);

  @override
  void destroy() {
    _data.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
