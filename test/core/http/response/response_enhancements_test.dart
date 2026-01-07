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
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    return values?.isNotEmpty == true ? values!.first : null;
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
  Future addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _writes.add(chunk);
    }
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
  final MockHttpHeaders _headers = MockHttpHeaders();

  @override
  HttpResponse get response => _response;

  @override
  HttpHeaders get headers => _headers;

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

    test('problem() sends RFC 7807 response', () {
      responseObj.problem(
        title: 'Not Found',
        status: 404,
        detail: 'User not found',
        type: 'https://example.com/probs/not-found',
      );

      final response = request.response as MockHttpResponse;
      final headers = response.headers as MockHttpHeaders;

      expect(response.statusCode, 404);
      expect(headers.contentType?.mimeType, 'application/problem+json');
      expect(response._writes.first, contains('"title":"Not Found"'));
      expect(response._writes.first, contains('"detail":"User not found"'));
    });

    test('back() redirects to referer', () async {
      request.headers.set('referer', '/previous-page');

      await responseObj.back();

      final response = request.response as MockHttpResponse;
      final headers = response.headers as MockHttpHeaders;

      expect(response.statusCode, 302);
      expect(headers.value('Location'), '/previous-page');
    });

    test('back() redirects to fallback if no referer', () async {
      await responseObj.back(fallback: '/home');

      final response = request.response as MockHttpResponse;
      final headers = response.headers as MockHttpHeaders;

      expect(response.statusCode, 302);
      expect(headers.value('Location'), '/home');
    });

    test('format() negotiates content type', () async {
      request.headers.set('Accept', 'application/json');

      bool jsonCalled = false;
      bool htmlCalled = false;

      await responseObj.format({
        'json': () {
          jsonCalled = true;
        },
        'html': () {
          htmlCalled = true;
        },
      });

      expect(jsonCalled, isTrue);
      expect(htmlCalled, isFalse);
    });

    test('cookie() adds a cookie to the response', () {
      responseObj.cookie(
        'test_cookie',
        'test_value',
        maxAge: const Duration(hours: 1),
      );

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
      expect(headers.value('X-Test-1'), 'Value1');
      expect(headers.value('X-Test-2'), 'Value2');
    });

    test('gzip() enables compression', () {
      responseObj.gzip();

      final headers = request.response.headers as MockHttpHeaders;
      expect(headers.value('Content-Encoding'), 'gzip');

      responseObj.send('Hello');

      final response = request.response as MockHttpResponse;
      expect(response._writes.first, isA<List<int>>()); // Should be bytes
    });

    test('gzip() compresses JSON', () {
      responseObj.gzip();
      responseObj.json({'key': 'value'});

      final headers = request.response.headers as MockHttpHeaders;
      expect(headers.value('Content-Encoding'), 'gzip');

      final response = request.response as MockHttpResponse;
      expect(response._writes.first, isA<List<int>>()); // Should be bytes
    });
  });
}
