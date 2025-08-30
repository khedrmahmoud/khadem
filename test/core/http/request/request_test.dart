import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../../lib/src/core/http/request/index.dart';

class FakeHttpRequest extends Stream<Uint8List> implements HttpRequest {
  @override
  String method = 'GET';

  @override
  Uri uri = Uri.parse('/test?param=value');

  @override
  HttpHeaders headers = FakeHttpHeaders();

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    // Return a subscription with some dummy JSON data
    final data = Uint8List.fromList('{"name": "test", "value": 123}'.codeUnits);
    return Stream<Uint8List>.fromIterable([data]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json'],
    'user-agent': ['TestAgent/1.0'],
    'authorization': ['Bearer token123'],
    'accept': ['application/json'],
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
  group('Request', () {
    late FakeHttpRequest fakeHttpRequest;
    late Request request;

    setUp(() {
      fakeHttpRequest = FakeHttpRequest();
      request = Request(fakeHttpRequest);
    });

    group('Basic Properties', () {
      test('should expose HTTP method', () {
        expect(request.method, equals('GET'));
      });

      test('should expose URI path', () {
        expect(request.path, equals('/test'));
      });

      test('should expose full URI', () {
        expect(request.uri, equals(Uri.parse('/test?param=value')));
      });

      test('should expose query parameters', () {
        expect(request.query, equals({'param': 'value'}));
      });

      test('should expose raw HttpRequest', () {
        expect(request.raw, equals(fakeHttpRequest));
      });
    });

    group('Body Parsing', () {
      test('should parse JSON body', () async {
        // This would need a more sophisticated mock for actual body reading
        // For now, testing the interface
        expect(request.bodyParser, isNotNull);
      });

      test('should provide body shortcut', () async {
        final body = await request.body;
        expect(body, isNotNull);
        expect(body['name'], equals('test'));
        expect(body['value'], equals(123));
      });
    });

    group('Parameters', () {
      test('should handle path parameters', () {
        request.setParam('id', '123');
        expect(request.param('id'), equals('123'));
        expect(request.params.hasParam('id'), isTrue);
      });

      test('should handle custom attributes', () {
        request.setAttribute('session', {'id': 'abc123'});
        expect(request.attribute<Map<String, dynamic>>('session'), equals({'id': 'abc123'}));
        expect(request.params.hasAttribute('session'), isTrue);
      });
    });

    group('Authentication', () {
      test('should handle user authentication', () {
        final userData = {'id': 1, 'name': 'John', 'roles': ['admin', 'user']};
        request.setUser(userData);

        expect(request.user, equals(userData));
        expect(request.userId, equals(1));
        expect(request.isAuthenticated, isTrue);
        expect(request.isGuest, isFalse);
      });

      test('should handle unauthenticated state', () {
        expect(request.user, isNull);
        expect(request.userId, isNull);
        expect(request.isAuthenticated, isFalse);
        expect(request.isGuest, isTrue);
      });

      test('should handle role checking', () {
        final userData = {'id': 1, 'name': 'John', 'roles': ['admin', 'user']};
        request.setUser(userData);

        expect(request.hasRole('admin'), isTrue);
        expect(request.hasRole('moderator'), isFalse);
        expect(request.hasAnyRole(['admin', 'moderator']), isTrue);
        expect(request.hasAllRoles(['admin', 'user']), isTrue);
        expect(request.hasAllRoles(['admin', 'moderator']), isFalse);
      });

      test('should clear user', () {
        request.setUser({'id': 1, 'name': 'John'});
        expect(request.isAuthenticated, isTrue);

        request.clearUser();
        expect(request.isAuthenticated, isFalse);
      });
    });

    group('Headers', () {
      test('should access headers', () {
        expect(request.header('content-type'), equals('application/json'));
        expect(request.header('user-agent'), equals('TestAgent/1.0'));
        expect(request.hasHeader('authorization'), isTrue);
      });

      test('should provide header shortcuts', () {
        expect(request.contentType, equals('application/json'));
        expect(request.userAgent, equals('TestAgent/1.0'));
      });

      test('should check content type preferences', () {
        expect(request.acceptsJson(), isTrue);
        expect(request.acceptsHtml(), isFalse);
      });

      test('should detect AJAX requests', () {
        expect(request.isAjax(), isFalse);
      });
    });

    group('Validation', () {
      test('should provide validation interface', () {
        expect(request.validator, isNotNull);
        expect(request.validate, isNotNull);
        expect(request.validateData, isNotNull);
      });
    });

    group('Component Access', () {
      test('should provide access to all components', () {
        expect(request.bodyParser, isA<RequestBodyParser>());
        expect(request.validator, isA<RequestValidator>());
        expect(request.auth, isA<RequestAuth>());
        expect(request.headers, isA<RequestHeaders>());
        expect(request.params, isA<RequestParams>());
      });
    });
  });
}
