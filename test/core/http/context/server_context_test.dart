import 'dart:async';

import 'package:test/test.dart';

import '../../../../lib/src/core/http/context/server_context.dart';
import '../../../../lib/src/core/routing/route_match_result.dart';
import '../../../mocks/http_mocks.dart';



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
