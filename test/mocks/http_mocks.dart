import 'dart:io';

import 'package:khadem/src/core/http/cookie.dart';
import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/core/http/response/index.dart';
import 'package:khadem/src/core/routing/index.dart' show RouteMatchResult;

/// Mock HttpRequest for testing
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
  Map<String, String> get testParams => params.all;
  set testParams(Map<String, String> value) {
    // This is for test compatibility - in real usage, use setParam()
  }

  Map<String, dynamic> get testAttributes => params.attributes;
  set testAttributes(Map<String, dynamic> value) {
    // This is for test compatibility - in real usage, use setAttribute()
  }
}

class FakeResponse implements Response {
  @override
  HttpRequest get raw => FakeHttpRequest() as dynamic;

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
  Response setStatusCode(int code) => this;

  @override
  Response header(String name, String value) => this;

  @override
  void send(String text) {}

  @override
  void sendJson(Map<String, dynamic> data) {}

  @override
  Future<void> redirect(String url, {int status = 302}) async {}

  @override
  Future<void> stream<T>(
    Stream<T> stream, {
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
    List<int> Function(T)? toBytes,
  }) async {}

  @override
  Future<void> file(File file) async {}

  @override
  Future<void> view(
    String viewName, {
    Map<String, dynamic> data = const {},
  }) async {}

  @override
  void html(String html) {}

  @override
  void bytes(
    List<int> bytes, {
    String contentType = 'application/octet-stream',
  }) {}

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
  }) =>
      this;

  @override
  Response security({
    bool enableHsts = false,
    bool enableCsp = false,
    bool enableXFrameOptions = true,
    bool enableXContentTypeOptions = true,
    String? cspPolicy,
  }) =>
      this;

  @override
  Response cache(String value) => this;

  @override
  Response noCache() => this;

  @override
  Cookies get cookieHandler => Cookies(FakeHttpRequest() as dynamic);

  @override
  Response flashInput(Map<String, dynamic> inputData) {
    // TODO: implement flashInput
    throw UnimplementedError();
  }

  @override
  Response sessionPut(String key, value) {
    // TODO: implement sessionPut
    throw UnimplementedError();
  }

  @override
  // TODO: implement statusCode
  int get statusCode => throw UnimplementedError();
}

class MockRouteMatchResult extends RouteMatchResult {
  MockRouteMatchResult(Map<String, String> params)
      : super(
          handler: (Request req, Response res) async {},
          params: params,
          middleware: [],
        );
}
