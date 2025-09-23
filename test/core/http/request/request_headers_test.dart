import 'dart:io';

import 'package:khadem/src/core/http/request/request_headers.dart';
import 'package:test/test.dart';

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json'],
    'user-agent': ['TestAgent/1.0'],
    'authorization': ['Bearer token123'],
    'accept': ['application/json, text/plain'],
    'accept-language': ['en-US, en'],
    'cache-control': ['no-cache'],
    'x-custom-header': ['custom-value'],
    'host': ['localhost'],
  };

  @override
  bool get chunkedTransferEncoding => false;

  @override
  set chunkedTransferEncoding(bool value) {}

  @override
  int get contentLength => -1;

  @override
  set contentLength(int? value) {}

  @override
  ContentType? get contentType => ContentType.json;

  @override
  set contentType(ContentType? value) {}

  @override
  DateTime? get date => null;

  @override
  set date(DateTime? value) {}

  @override
  DateTime? get expires => null;

  @override
  set expires(DateTime? value) {}

  @override
  String? get host => 'localhost';

  @override
  set host(String? value) {}

  @override
  DateTime? get ifModifiedSince => null;

  @override
  set ifModifiedSince(DateTime? value) {}

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool value) {}

  @override
  int? get port => 8080;

  @override
  set port(int? value) {}

  @override
  String? value(String name) => _headers[name.toLowerCase()]?.first;

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

void main() {
  group('RequestHeaders', () {
    late RequestHeaders headers;
    late FakeHttpHeaders fakeHttpHeaders;

    setUp(() {
      fakeHttpHeaders = FakeHttpHeaders();
      headers = RequestHeaders(fakeHttpHeaders);
    });

    group('Basic Header Access', () {
      test('should get header value', () {
        expect(headers.header('content-type'), equals('application/json'));
        expect(headers.header('user-agent'), equals('TestAgent/1.0'));
        expect(headers.header('nonexistent'), isNull);
      });

      test('should get all header values', () {
        final values = headers.headerValues('accept');
        expect(values, isNotNull);
        expect(values!.first, equals('application/json, text/plain'));
      });

      test('should check if header exists', () {
        expect(headers.hasHeader('content-type'), isTrue);
        expect(headers.hasHeader('nonexistent'), isFalse);
      });
    });

    group('Common Headers', () {
      test('should get content type', () {
        expect(headers.contentType, equals('application/json'));
      });

      test('should get user agent', () {
        expect(headers.userAgent, equals('TestAgent/1.0'));
      });

      test('should get authorization header', () {
        expect(headers.authorization, equals('Bearer token123'));
      });

      test('should get accept header', () {
        expect(headers.accept, equals('application/json, text/plain'));
      });

      test('should get forwarded for header', () {
        expect(headers.forwardedFor, isNull);
      });

      test('should get real ip header', () {
        expect(headers.realIp, isNull);
      });

      test('should get origin header', () {
        expect(headers.origin, isNull);
      });

      test('should get referer header', () {
        expect(headers.referer, isNull);
      });

      test('should get host header', () {
        expect(headers.host, equals('localhost'));
      });
    });

    group('Content Negotiation', () {
      test('should check if accepts JSON', () {
        expect(headers.acceptsJson(), isTrue);
      });

      test('should check if accepts HTML', () {
        expect(headers.acceptsHtml(), isFalse);
      });
    });

    group('AJAX Detection', () {
      test('should detect AJAX requests', () {
        expect(headers.isAjax(), isFalse);
      });
    });

    group('Raw Headers Access', () {
      test('should provide access to raw headers', () {
        expect(headers.headers, isNotNull);
        expect(headers.headers, equals(fakeHttpHeaders));
      });
    });

    group('Edge Cases', () {
      test('should handle case insensitive header names', () {
        expect(headers.header('CONTENT-TYPE'), equals('application/json'));
        expect(headers.header('Content-Type'), equals('application/json'));
      });

      test('should handle missing headers gracefully', () {
        expect(headers.header('nonexistent'), isNull);
        expect(headers.hasHeader('nonexistent'), isFalse);
      });
    });
  });
}
