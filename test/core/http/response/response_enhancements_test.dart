import 'dart:io';

import 'package:khadem/src/core/http/response/response.dart';
import 'package:test/test.dart';

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};
  ContentType? _contentType;

  @override
  ContentType? get contentType => _contentType;

  @override
  set contentType(ContentType? value) => _contentType = value;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpResponse implements HttpResponse {
  final MockHttpHeaders _headers = MockHttpHeaders();
  final List<dynamic> _writes = [];
  final List<Cookie> _cookies = [];

  @override
  HttpHeaders get headers => _headers;

  @override
  List<Cookie> get cookies => _cookies;

  @override
  int statusCode = 200;

  @override
  void write(Object? object) {
    _writes.add(object);
  }

  @override
  void add(List<int> data) {
    _writes.add(data);
  }

  @override
  Future close() async {
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpRequest implements HttpRequest {
  final MockHttpResponse _response = MockHttpResponse();

  @override
  HttpResponse get response => _response;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Response Enhancements', () {
    late MockHttpRequest request;
    late Response responseObj;

    setUp(() {
      request = MockHttpRequest();
      responseObj = Response(request);
    });

    test('cookie() adds a cookie to the response', () {
      responseObj.cookie('test_cookie', 'test_value',
          maxAge: Duration(hours: 1));

      final cookies = request.response.cookies;
      expect(cookies, hasLength(1));
      expect(cookies.first.name, 'test_cookie');
      expect(cookies.first.value, 'test_value');
      expect(cookies.first.maxAge, 3600);
    });

    test('withHeaders() sets multiple headers', () {
      responseObj.withHeaders({
        'X-Test-1': 'Value1',
        'X-Test-2': 'Value2',
      });

      final headers = request.response.headers as MockHttpHeaders;
      expect(headers._headers['X-Test-1'], contains('Value1'));
      expect(headers._headers['X-Test-2'], contains('Value2'));
    });

    test('gzip() enables compression', () {
      responseObj.gzip();

      final headers = request.response.headers as MockHttpHeaders;
      expect(headers._headers['Content-Encoding'], contains('gzip'));

      responseObj.send('Hello');

      final response = request.response as MockHttpResponse;
      expect(response._writes.first, isA<List<int>>()); // Should be bytes
    });

    test('gzip() compresses JSON', () {
      responseObj.gzip();
      responseObj.json({'key': 'value'});

      final headers = request.response.headers as MockHttpHeaders;
      expect(headers._headers['Content-Encoding'], contains('gzip'));

      final response = request.response as MockHttpResponse;
      expect(response._writes.first, isA<List<int>>()); // Should be bytes
    });
  });
}
