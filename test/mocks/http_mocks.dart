import 'dart:io';

/// Mock HttpRequest for testing
class MockHttpRequest implements HttpRequest {
  @override
  final String method;
  @override
  final Uri uri;
  @override
  final HttpHeaders headers = MockHttpHeaders();
  @override
  final HttpResponse response = MockHttpResponse();

  MockHttpRequest(String method, String path)
      : method = method.toUpperCase(),
        uri = Uri.parse(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpResponse implements HttpResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
