import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import '../../../../lib/src/core/http/context/server_context.dart';
import '../../../../lib/src/core/http/request/request.dart';
import '../../../../lib/src/core/http/response/response.dart';
import '../../../../lib/src/core/http/response/response_body.dart';
import '../../../../lib/src/core/http/response/response_headers.dart';
import '../../../../lib/src/core/http/response/response_renderer.dart';
import '../../../../lib/src/core/http/response/response_status.dart';
import '../../../../lib/src/core/routing/route_match_result.dart';

class FakeHttpRequest implements HttpRequest {
  @override
  String method = 'GET';

  @override
  Uri uri = Uri.parse('/test');

  @override
  HttpHeaders headers = FakeHttpHeaders();

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

class FakeRequest extends Request {
  FakeRequest() : super(FakeHttpRequest()) {
    // Initialize with empty params and attributes for testing
  }

  // For backward compatibility in tests, provide access to params as a map
  Map<String, String> get testParams => params.pathParams;
  set testParams(Map<String, String> value) {
    // This is for test compatibility - in real usage, use setParam()
  }

  Map<String, dynamic> get testAttributes => params.attributes;
  set testAttributes(Map<String, dynamic> value) {
    // This is for test compatibility - in real usage, use setAttribute()
  }
}

class FakeHttpResponse {
  int statusCode = 200;
}

class FakeResponse implements Response {
  final FakeHttpRequest _raw = FakeHttpRequest();

  @override
  HttpRequest get raw => _raw as dynamic;

  @override
  bool sent = false;

  @override
  ResponseHeaders get headers => throw UnimplementedError();

  @override
  ResponseStatus get statusManager => throw UnimplementedError();

  @override
  ResponseBody get body => throw UnimplementedError();

  @override
  ResponseRenderer get renderer => throw UnimplementedError();

  @override
  Response status(int code) => this;

  @override
  Response statusCode(int code) => this;

  @override
  Response header(String name, String value) => this;

  @override
  void send(String text) {}

  @override
  void sendJson(Map<String, dynamic> data) {}

  @override
  Future<void> redirect(String url, {int status = 302}) async {}

  @override
  Future<void> stream<T>(Stream<T> stream, {String contentType = 'application/octet-stream', Map<String, String>? headers, List<int> Function(T)? toBytes}) async {}

  @override
  Future<void> file(File file) async {}

  @override
  Future<void> view(String viewName, {Map<String, dynamic> data = const {}}) async {}

  @override
  void html(String html) {}

  @override
  void bytes(List<int> bytes, {String contentType = 'application/octet-stream'}) {}

  @override
  void jsonPretty(dynamic data, {int indent = 2}) {}

  @override
  void empty() {}

  @override
  Response ok() => this;

  @override
  Response created() => this;

  @override
  Response accepted() => this;

  @override
  Response noContent() => this;

  @override
  Response badRequest() => this;

  @override
  Response unauthorized() => this;

  @override
  Response forbidden() => this;

  @override
  Response notFound() => this;

  @override
  Response internalServerError() => this;

  @override
  Response cors({
    String? allowOrigin,
    String? allowMethods,
    String? allowHeaders,
    String? exposeHeaders,
    bool allowCredentials = false,
    int? maxAge,
  }) => this;

  @override
  Response security({
    bool enableHsts = false,
    bool enableCsp = false,
    bool enableXFrameOptions = true,
    bool enableXContentTypeOptions = true,
    String? cspPolicy,
  }) => this;

  @override
  Response cache(String value) => this;

  @override
  Response noCache() => this;
}

class MockRouteMatchResult extends RouteMatchResult {
  MockRouteMatchResult(Map<String, String> params)
      : super(
          handler: (Request req, Response res) async {},
          params: params,
          middleware: [],
        );
}

void main() {
  group('ServerContext', () {
    late FakeRequest mockRequest;
    late FakeResponse mockResponse;
    late RouteMatchResult? Function(String method, String path) mockMatcher;

    setUp(() {
      mockRequest = FakeRequest();
      mockResponse = FakeResponse();
      mockMatcher = (method, path) => MockRouteMatchResult({'id': '123'});
    });

    tearDown(() {
      // Clean up any context data
    });

    group('Initialization', () {
      test('should create server context with required parameters', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        expect(context.request, equals(mockRequest));
        expect(context.response, equals(mockResponse));
        expect(context.match, equals(mockMatcher));
      });

      test('should create server context without matcher', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: null,
        );

        expect(context.hasMatch, isFalse);
        expect(context.matchedRoute, isNull);
      });
    });

    group('Route Matching', () {
      test('should return true when matcher is provided', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        expect(context.hasMatch, isTrue);
      });

      test('should return matched route result', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        final result = context.matchedRoute;
        expect(result, isNotNull);
        expect(result!.params['id'], equals('123'));
        expect(result.params, equals({'id': '123'}));
      });

      test('should return null when no matcher provided', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: null,
        );

        expect(context.matchedRoute, isNull);
      });
    });

    group('Processing Time', () {
      test('should track processing time', () async {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 10));

        final duration = context.processingTime;
        expect(duration.inMilliseconds, greaterThanOrEqualTo(10));
        expect(duration.inMilliseconds, lessThan(100)); // Shouldn't be too long
      });
    });

    group('Custom Data Storage', () {
      test('should store and retrieve custom data', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        context.setData('user_id', '123');
        context.setData('session_id', 'abc');

        expect(context.getData<String>('user_id'), equals('123'));
        expect(context.getData<String>('session_id'), equals('abc'));
        expect(context.hasData('user_id'), isTrue);
        expect(context.hasData('nonexistent'), isFalse);
      });

      test('should return null for non-existent data', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        expect(context.getData<String>('nonexistent'), isNull);
      });

      test('should remove data', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        context.setData('test', 'value');
        expect(context.hasData('test'), isTrue);

        context.removeData('test');
        expect(context.hasData('test'), isFalse);
      });

      test('should clear all data', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        context.setData('key1', 'value1');
        context.setData('key2', 'value2');
        expect(context.allData.length, equals(2));

        context.clearData();
        expect(context.allData.length, equals(0));
      });

      test('should return unmodifiable data map', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        context.setData('test', 'value');
        final data = context.allData;

        expect(() => data['new_key'] = 'new_value', throwsUnsupportedError);
      });
    });

    group('Zone Execution', () {
      test('should execute function in server context zone', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        final result = context.run(() {
          // Verify we're in the correct zone
          final zoneContext = Zone.current[ServerContext.zoneKey];
          expect(zoneContext, equals(context));
          return 'success';
        });

        expect(result, equals('success'));
      });

      test('should handle exceptions in zone execution', () {
        final context = ServerContext(
          request: mockRequest,
          response: mockResponse,
          match: mockMatcher,
        );

        expect(() => context.run(() => throw Exception('test error')), throwsException);
      });
    });

    group('Zone Key', () {
      test('should have correct zone key', () {
        expect(ServerContext.zoneKey, equals(#serverContext));
      });
    });
  });
}
