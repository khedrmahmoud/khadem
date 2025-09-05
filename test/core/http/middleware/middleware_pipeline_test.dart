import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import '../../../../lib/src/contracts/http/middleware_contract.dart';
import '../../../../lib/src/core/http/middleware/middleware_pipeline.dart';
import '../../../../lib/src/core/http/request/index.dart';
import '../../../../lib/src/core/http/response/response.dart';
import '../../../../lib/src/core/http/response/response_body.dart';
import '../../../../lib/src/core/http/response/response_headers.dart';
import '../../../../lib/src/core/http/response/response_renderer.dart';
import '../../../../lib/src/core/http/response/response_status.dart';
import '../../../../lib/src/support/exceptions/middleware_not_found_exception.dart';

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
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json'],
    'user-agent': ['TestAgent/1.0'],
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

void main() {
  group('MiddlewarePipeline', () {
    late MiddlewarePipeline pipeline;
    late FakeRequest request;
    late FakeResponse response;

    setUp(() {
      pipeline = MiddlewarePipeline();
      request = FakeRequest();
      response = FakeResponse();
    });

    tearDown(() {
      pipeline.clear();
    });

    group('Initialization', () {
      test('should create empty pipeline', () {
        expect(pipeline.middleware, isEmpty);
        expect(pipeline.hasMiddleware('test'), isFalse);
      });
    });

    group('Adding Middleware', () {
      test('should add middleware handler', () {
        pipeline.add((req, res, next) async {
          await next();
        }, name: 'test',);

        expect(pipeline.middleware.length, equals(1));
        expect(pipeline.hasMiddleware('test'), isTrue);
        expect(pipeline.getByName('test')?.name, equals('test'));
      });

      test('should add middleware object', () {
        final middleware = Middleware((req, res, next) async {
          await next();
        }, name: 'test',);

        pipeline.addMiddleware(middleware);

        expect(pipeline.middleware.length, equals(1));
        expect(pipeline.hasMiddleware('test'), isTrue);
      });

      test('should add multiple handlers', () {
        pipeline.addAll([
          (req, res, next) async => await next(),
          (req, res, next) async => await next(),
        ]);

        expect(pipeline.middleware.length, equals(2));
      });

      test('should add multiple middleware objects', () {
        final middlewares = [
          Middleware((req, res, next) async => await next(), name: 'first'),
          Middleware((req, res, next) async => await next(), name: 'second'),
        ];

        pipeline.addMiddlewares(middlewares);

        expect(pipeline.middleware.length, equals(2));
        expect(pipeline.hasMiddleware('first'), isTrue);
        expect(pipeline.hasMiddleware('second'), isTrue);
      });

      test('should assign default name when not provided', () {
        pipeline.add((req, res, next) async => await next());

        expect(pipeline.middleware.length, equals(1));
        expect(pipeline.middleware.first.name, startsWith('anonymous-'));
      });
    });

    group('Middleware Ordering', () {
      test('should sort middleware by priority', () {
        pipeline.add((req, res, next) async => await next(), name: 'business',);
        pipeline.add((req, res, next) async => await next(),
            priority: MiddlewarePriority.global, name: 'global',);
        pipeline.add((req, res, next) async => await next(),
            priority: MiddlewarePriority.auth, name: 'auth',);

        final middleware = pipeline.middleware;
        expect(middleware[0].name, equals('global'));
        expect(middleware[1].name, equals('auth'));
        expect(middleware[2].name, equals('business'));
      });
    });

    group('Named Middleware Operations', () {
      test('should add middleware before named middleware', () {
        pipeline.add((req, res, next) async => await next(), name: 'target');
        pipeline.addBefore('target', (req, res, next) async => await next(), name: 'before');

        final middleware = pipeline.middleware;
        expect(middleware[0].name, equals('before'));
        expect(middleware[1].name, equals('target'));
      });

      test('should add middleware after named middleware', () {
        pipeline.add((req, res, next) async => await next(), name: 'target');
        pipeline.addAfter('target', (req, res, next) async => await next(), name: 'after');

        final middleware = pipeline.middleware;
        expect(middleware[0].name, equals('target'));
        expect(middleware[1].name, equals('after'));
      });

      test('should throw when adding before non-existent middleware', () {
        expect(() => pipeline.addBefore('nonexistent', (req, res, next) async => await next()),
            throwsA(isA<MiddlewareNotFoundException>()),);
      });

      test('should throw when adding after non-existent middleware', () {
        expect(() => pipeline.addAfter('nonexistent', (req, res, next) async => await next()),
            throwsA(isA<MiddlewareNotFoundException>()),);
      });

      test('should remove middleware by name', () {
        pipeline.add((req, res, next) async => await next(), name: 'test');
        expect(pipeline.hasMiddleware('test'), isTrue);

        pipeline.remove('test');
        expect(pipeline.hasMiddleware('test'), isFalse);
        expect(pipeline.middleware, isEmpty);
      });

      test('should handle removing non-existent middleware gracefully', () {
        pipeline.remove('nonexistent'); // Should not throw
        expect(pipeline.middleware, isEmpty);
      });
    });

    group('Processing', () {
      test('should process request through middleware chain', () async {
        final order = <String>[];

        pipeline.add((req, res, next) async {
          order.add('first');
          await next();
          order.add('first-after');
        }, name: 'first',);

        pipeline.add((req, res, next) async {
          order.add('second');
          await next();
          order.add('second-after');
        }, name: 'second',);

        await pipeline.process(request, response);

        expect(order, equals(['first', 'second', 'second-after', 'first-after']));
      });

      test('should handle middleware that does not call next', () async {
        var called = false;

        pipeline.add((req, res, next) async {
          called = true;
          // Does not call next
        }, name: 'blocking',);

        pipeline.add((req, res, next) async {
          fail('Should not be reached');
        }, name: 'never-called',);

        await pipeline.process(request, response);

        expect(called, isTrue);
      });

      test('should handle async middleware', () async {
        var completed = false;

        pipeline.add((req, res, next) async {
          await Future.delayed(const Duration(milliseconds: 10));
          completed = true;
          await next();
        });

        await pipeline.process(request, response);

        expect(completed, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle exceptions in middleware', () async {
        var errorHandled = false;

        pipeline.add((req, res, next) async {
          throw Exception('Test error');
        });

        pipeline.add((req, res, next) async {
          errorHandled = true;
          await next();
        }, priority: MiddlewarePriority.terminating,);

        await pipeline.process(request, response);

        expect(errorHandled, isTrue);
        expect(request.attribute<String>('error'), equals('Exception: Test error'));
        expect(request.attribute<String>('stackTrace'), isNotNull);
      });

      test('should handle multiple terminating middleware', () async {
        var handler1Called = false;
        var handler2Called = false;

        pipeline.add((req, res, next) async {
          throw Exception('Test error');
        });

        pipeline.add((req, res, next) async {
          handler1Called = true;
          await next();
        }, priority: MiddlewarePriority.terminating, name: 'handler1',);

        pipeline.add((req, res, next) async {
          handler2Called = true;
          await next();
        }, priority: MiddlewarePriority.terminating, name: 'handler2',);

        await pipeline.process(request, response);

        expect(handler1Called, isTrue);
        expect(handler2Called, isTrue);
      });

      test('should rethrow MiddlewareNotFoundException', () async {
        pipeline.add((req, res, next) async {
          throw MiddlewareNotFoundException('Test middleware not found');
        });

        expect(() async => await pipeline.process(request, response),
            throwsA(isA<MiddlewareNotFoundException>()),);
      });
    });

    group('Utility Methods', () {
      test('should return unmodifiable middleware list', () {
        pipeline.add((req, res, next) async => await next(), name: 'test');

        final middleware = pipeline.middleware;
        expect(() => middleware.clear(), throwsUnsupportedError);
      });

      test('should get middleware by name', () {
        final middleware = Middleware((req, res, next) async => await next(), name: 'test');
        pipeline.addMiddleware(middleware);

        final retrieved = pipeline.getByName('test');
        expect(retrieved, equals(middleware));
      });

      test('should return null for non-existent middleware', () {
        expect(pipeline.getByName('nonexistent'), isNull);
      });

      test('should check middleware existence', () {
        expect(pipeline.hasMiddleware('test'), isFalse);

        pipeline.add((req, res, next) async => await next(), name: 'test');
        expect(pipeline.hasMiddleware('test'), isTrue);
      });

      test('should clear all middleware', () {
        pipeline.add((req, res, next) async => await next(), name: 'first');
        pipeline.add((req, res, next) async => await next(), name: 'second');

        expect(pipeline.middleware.length, equals(2));

        pipeline.clear();

        expect(pipeline.middleware, isEmpty);
        expect(pipeline.hasMiddleware('first'), isFalse);
        expect(pipeline.hasMiddleware('second'), isFalse);
      });
    });
  });
}
