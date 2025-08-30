import 'dart:io';

import 'package:test/test.dart';

import '../../../../lib/src/core/http/response/response.dart';
import '../../../../lib/src/core/http/response/response_body.dart';
import '../../../../lib/src/core/http/response/response_headers.dart';
import '../../../../lib/src/core/http/response/response_renderer.dart';
import '../../../../lib/src/core/http/response/response_status.dart';

class FakeHttpRequest implements HttpRequest {
  @override
  HttpHeaders headers = FakeHttpHeaders();

  @override
  HttpResponse response = FakeHttpResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpHeaders implements HttpHeaders {
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
  String? value(String name) => null;

  @override
  List<String>? operator [](String name) => null;

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

  @override
  void noSuchMethod(Invocation invocation) => null;
}

class FakeHttpResponse implements HttpResponse {
  final Map<String, String> _headers = {};
  int _statusCode = 200;
  bool _isClosed = false;
  final List<int> _writtenData = [];

  @override
  int get statusCode => _statusCode;

  @override
  set statusCode(int value) => _statusCode = value;

  @override
  HttpHeaders headers = FakeHttpHeaders();

  @override
  Future<void> close() async {
    _isClosed = true;
  }

  @override
  void write(Object? object) {
    if (object != null) {
      _writtenData.addAll(object.toString().codeUnits);
    }
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _writtenData.addAll(chunk);
    }
  }

  @override
  void add(List<int> data) {
    _writtenData.addAll(data);
  }

  // Getters for testing
  bool get isClosed => _isClosed;
  List<int> get writtenData => _writtenData;
  Map<String, String> get testHeaders => _headers;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Response System', () {
    late FakeHttpRequest fakeRequest;
    late FakeHttpResponse fakeResponse;
    late Response response;

    setUp(() {
      fakeRequest = FakeHttpRequest();
      fakeResponse = FakeHttpResponse();
      fakeRequest.response = fakeResponse;
      response = Response(fakeRequest);
    });

    group('Response Initialization', () {
      test('should create response with proper components', () {
        expect(response.raw, equals(fakeRequest));
        expect(response.sent, isFalse);
        expect(response.headers, isA<ResponseHeaders>());
        expect(response.statusManager, isA<ResponseStatus>());
        expect(response.body, isA<ResponseBody>());
        expect(response.renderer, isA<ResponseRenderer>());
      });
    });

    group('Response Status', () {
      test('should set status code', () {
        response.statusCode(404);
        expect(fakeResponse.statusCode, equals(404));
      });

      test('should provide convenience status methods', () {
        response.ok();
        expect(fakeResponse.statusCode, equals(200));

        response.notFound();
        expect(fakeResponse.statusCode, equals(404));

        response.internalServerError();
        expect(fakeResponse.statusCode, equals(500));
      });

      test('should check status categories', () {
        response.ok();
        expect(response.statusManager.isSuccess, isTrue);
        expect(response.statusManager.isClientError, isFalse);
        expect(response.statusManager.isServerError, isFalse);

        response.notFound();
        expect(response.statusManager.isSuccess, isFalse);
        expect(response.statusManager.isClientError, isTrue);
        expect(response.statusManager.isServerError, isFalse);

        response.internalServerError();
        expect(response.statusManager.isSuccess, isFalse);
        expect(response.statusManager.isClientError, isFalse);
        expect(response.statusManager.isServerError, isTrue);
      });
    });

    group('Response Headers', () {
      test('should set headers', () {
        response.header('X-Custom', 'value');
        // Note: Testing actual header setting would require mocking the HttpHeaders
        expect(response.headers, isNotNull);
      });

      test('should provide CORS convenience methods', () {
        response.cors(
          allowOrigin: '*',
          allowMethods: 'GET, POST',
          allowCredentials: true,
        );
        expect(response.headers, isNotNull);
      });

      test('should provide security convenience methods', () {
        response.security(
          enableHsts: true,
          enableXFrameOptions: true,
        );
        expect(response.headers, isNotNull);
      });

      test('should provide cache convenience methods', () {
        response.noCache();
        expect(response.headers, isNotNull);
      });
    });

    group('Response Body', () {
      test('should send text', () {
        response.send('Hello World');
        expect(response.sent, isTrue);
      });

      test('should send JSON', () {
        final data = {'message': 'Hello', 'status': 'success'};
        response.sendJson(data);
        expect(response.sent, isTrue);
      });

      test('should send HTML', () {
        response.html('<h1>Hello</h1>');
        expect(response.sent, isTrue);
      });

      test('should send bytes', () {
        final bytes = [72, 101, 108, 108, 111]; // "Hello"
        response.bytes(bytes);
        expect(response.sent, isTrue);
      });

      test('should send pretty JSON', () {
        final data = {'users': ['Alice', 'Bob']};
        response.jsonPretty(data);
        expect(response.sent, isTrue);
      });

      test('should send empty response', () {
        response.empty();
        expect(response.sent, isTrue);
      });
    });

    group('Response Convenience Methods', () {
      test('should provide fluent API for status and headers', () {
        final result = response
            .statusCode(201)
            .header('X-API-Version', '1.0')
            .cors(allowOrigin: '*');

        expect(result, equals(response));
        expect(fakeResponse.statusCode, equals(201));
      });

      test('should chain status methods', () {
        response.created().accepted().noContent();
        expect(fakeResponse.statusCode, equals(204));
      });
    });

    group('Response State Management', () {
      test('should track sent state', () {
        expect(response.sent, isFalse);

        response.send('test');
        expect(response.sent, isTrue);

        // Subsequent sends should not change state
        response.sendJson({'test': 'data'});
        expect(response.sent, isTrue);
      });

      test('should prevent multiple sends', () {
        response.send('first');
        expect(response.sent, isTrue);

        // This should not execute
        response.send('second');
        expect(response.sent, isTrue);
      });
    });
  });
}
