import 'package:khadem/src/core/http/request/request_params.dart';
import 'package:test/test.dart';

void main() {
  group('RequestParams', () {
    late RequestParams params;

    setUp(() {
      params = RequestParams({}, {});
    });

    group('Path Parameters', () {
      test('should set and get path parameters', () {
        params.setParam('id', '123');
        params.setParam('action', 'edit');

        expect(params.param('id'), equals('123'));
        expect(params.param('action'), equals('edit'));
        expect(params.param('nonexistent'), isNull);
      });

      test('should check if parameter exists', () {
        params.setParam('id', '123');

        expect(params.hasParam('id'), isTrue);
        expect(params.hasParam('nonexistent'), isFalse);
      });

      test('should get parameter with default value', () {
        expect(
          params.paramWithDefault('nonexistent', 'default'),
          equals('default'),
        );
        params.setParam('existing', 'value');
        expect(params.paramWithDefault('existing', 'default'), equals('value'));
      });

      test('should get all parameter keys', () {
        params.setParam('id', '123');
        params.setParam('action', 'edit');

        final keys = params.paramKeys;

        expect(keys, contains('id'));
        expect(keys, contains('action'));
        expect(keys.length, equals(2));
      });

      test('should clear parameters', () {
        params.setParam('id', '123');
        expect(params.hasParam('id'), isTrue);

        params.clearParams();
        expect(params.hasParam('id'), isFalse);
      });

      test('should remove specific parameter', () {
        params.setParam('id', '123');
        params.setParam('action', 'edit');

        params.removeParam('id');

        expect(params.hasParam('id'), isFalse);
        expect(params.hasParam('action'), isTrue);
      });
    });

    group('Custom Attributes', () {
      test('should set and get attributes', () {
        final user = {'id': 1, 'name': 'John'};
        params.setAttribute('user', user);
        params.setAttribute('session_id', 'abc123');

        expect(params.attribute('user'), equals(user));
        expect(params.attribute('session_id'), equals('abc123'));
        expect(params.attribute('nonexistent'), isNull);
      });

      test('should check if attribute exists', () {
        params.setAttribute('user', {'id': 1});

        expect(params.hasAttribute('user'), isTrue);
        expect(params.hasAttribute('nonexistent'), isFalse);
      });

      test('should get typed attributes', () {
        final user = {'id': 1, 'name': 'John'};
        params.setAttribute('user', user);

        final retrievedUser = params.attribute<Map<String, dynamic>>('user');
        expect(retrievedUser, equals(user));
        expect(retrievedUser!['id'], equals(1));
      });

      test('should get all attribute keys', () {
        params.setAttribute('user', {'id': 1});
        params.setAttribute('session', {'id': 'abc123'});

        final keys = params.attributeKeys;

        expect(keys, contains('user'));
        expect(keys, contains('session'));
        expect(keys.length, equals(2));
      });

      test('should clear attributes', () {
        params.setAttribute('user', {'id': 1});
        expect(params.hasAttribute('user'), isTrue);

        params.clearAttributes();
        expect(params.hasAttribute('user'), isFalse);
      });

      test('should remove specific attribute', () {
        params.setAttribute('user', {'id': 1});
        params.setAttribute('session', {'id': 'abc123'});

        params.removeAttribute('user');

        expect(params.hasAttribute('user'), isFalse);
        expect(params.hasAttribute('session'), isTrue);
      });

      test('should handle complex attribute types', () {
        final complexData = {
          'user': {
            'id': 1,
            'roles': ['admin', 'user'],
          },
          'permissions': ['read', 'write', 'delete'],
          'metadata': {'created_at': DateTime.now(), 'version': 1.0},
        };

        params.setAttribute('data', complexData);

        final retrieved = params.attribute<Map<String, dynamic>>('data');
        expect(retrieved, equals(complexData));
        expect(retrieved!['user']['roles'], contains('admin'));
      });
    });

    group('Combined Operations', () {
      test('should handle both params and attributes independently', () {
        params.setParam('id', '123');
        params.setAttribute('user', {'id': 1});

        expect(params.param('id'), equals('123'));
        expect(params.attribute('user'), equals({'id': 1}));

        // Clearing params shouldn't affect attributes
        params.clearParams();
        expect(params.hasParam('id'), isFalse);
        expect(params.hasAttribute('user'), isTrue);

        // Clearing attributes shouldn't affect params
        params.setParam('id', '456');
        params.clearAttributes();
        expect(params.hasParam('id'), isTrue);
        expect(params.hasAttribute('user'), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle null values', () {
        params.setAttribute('attr', null);

        expect(params.attribute('attr'), isNull);
      });

      test('should handle empty strings', () {
        params.setParam('empty', '');
        params.setAttribute('empty_attr', '');

        expect(params.param('empty'), equals(''));
        expect(params.attribute('empty_attr'), equals(''));
      });

      test('should handle overwriting values', () {
        params.setParam('id', '123');
        params.setParam('id', '456');

        expect(params.param('id'), equals('456'));

        params.setAttribute('user', {'id': 1});
        params.setAttribute('user', {'id': 2});

        expect(params.attribute('user'), equals({'id': 2}));
      });
    });
  });
}
