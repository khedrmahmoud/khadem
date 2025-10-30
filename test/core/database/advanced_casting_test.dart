import 'dart:convert';

import 'package:khadem/src/core/database/orm/casting/built_in_casters.dart';
import 'package:test/test.dart';

void main() {
  group('JsonCast', () {
    late JsonCast caster;

    setUp(() {
      caster = JsonCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('converts Map to JSON string', () {
      final data = {'name': 'John', 'age': 30};
      final result = caster.set(data);

      expect(result, isA<String>());
      expect(jsonDecode(result), equals(data));
    });

    test('converts JSON string to Map', () {
      const jsonString = '{"name":"John","age":30}';
      final result = caster.get(jsonString);

      expect(result, isA<Map<String, dynamic>>());
      expect(result!['name'], equals('John'));
      expect(result['age'], equals(30));
    });

    test('returns Map as-is if already Map', () {
      final data = {'name': 'John'};
      final result = caster.get(data);

      expect(result, equals(data));
    });

    test('returns null for invalid JSON', () {
      expect(caster.get('invalid json'), isNull);
      expect(caster.get('{malformed}'), isNull);
    });

    test('handles nested objects', () {
      final data = {
        'user': {'name': 'John', 'age': 30},
        'settings': {'theme': 'dark'},
      };

      final encoded = caster.set(data);
      final decoded = caster.get(encoded);

      expect(decoded, equals(data));
      expect(decoded!['user']['name'], equals('John'));
    });
  });

  group('ArrayCast', () {
    late ArrayCast caster;

    setUp(() {
      caster = ArrayCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('converts List<String> to JSON array', () {
      final data = ['admin', 'editor', 'user'];
      final result = caster.set(data);

      expect(result, isA<String>());
      expect(jsonDecode(result), equals(data));
    });

    test('converts JSON array to List<String>', () {
      const jsonString = '["admin","editor","user"]';
      final result = caster.get(jsonString);

      expect(result, isA<List<String>>());
      expect(result, hasLength(3));
      expect(result![0], equals('admin'));
    });

    test('returns List<String> as-is if already List<String>', () {
      final data = ['tag1', 'tag2'];
      final result = caster.get(data);

      expect(result, equals(data));
    });

    test('converts mixed List to List<String>', () {
      final data = [1, 'text', true, 3.14];
      final result = caster.get(data);

      expect(result, isA<List<String>>());
      expect(result![0], equals('1'));
      expect(result[1], equals('text'));
      expect(result[2], equals('true'));
      expect(result[3], equals('3.14'));
    });

    test('returns null for invalid JSON', () {
      expect(caster.get('invalid json'), isNull);
    });

    test('handles empty arrays', () {
      final empty = <String>[];
      final encoded = caster.set(empty);
      final decoded = caster.get(encoded);

      expect(decoded, isEmpty);
    });
  });

  group('JsonArrayCast', () {
    late JsonArrayCast caster;

    setUp(() {
      caster = JsonArrayCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('converts List<Map> to JSON', () {
      final data = [
        {'name': 'John', 'age': 30},
        {'name': 'Jane', 'age': 25},
      ];
      final result = caster.set(data);

      expect(result, isA<String>());
      expect(jsonDecode(result), equals(data));
    });

    test('converts JSON to List<Map<String, dynamic>>', () {
      const jsonString = '[{"name":"John","age":30},{"name":"Jane","age":25}]';
      final result = caster.get(jsonString);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result, hasLength(2));
      expect(result![0]['name'], equals('John'));
      expect(result[1]['age'], equals(25));
    });

    test('returns List<Map> as-is if already correct type', () {
      final data = [
        {'id': 1},
        {'id': 2},
      ];
      final result = caster.get(data);

      expect(result, equals(data));
    });

    test('converts regular List to List<Map<String, dynamic>>', () {
      final data = [
        {'key': 'value'},
        {'another': 'map'},
      ];
      final result = caster.get(data);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('returns null for invalid JSON', () {
      expect(caster.get('not json'), isNull);
    });

    test('handles empty arrays', () {
      final empty = <Map<String, dynamic>>[];
      final encoded = caster.set(empty);
      final decoded = caster.get(encoded);

      expect(decoded, isEmpty);
    });

    test('handles complex nested structures', () {
      final data = [
        {
          'user': {'name': 'John', 'age': 30},
          'items': [1, 2, 3],
        },
      ];

      final encoded = caster.set(data);
      final decoded = caster.get(encoded);

      expect(decoded![0]['user']['name'], equals('John'));
      expect(decoded[0]['items'], equals([1, 2, 3]));
    });
  });

  group('EncryptedCast', () {
    late EncryptedCast caster;

    setUp(() {
      caster = EncryptedCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('hashes string values (one-way)', () {
      const password = 'my_secret_password';
      final hashed = caster.set(password);

      expect(hashed, isA<String>());
      expect(hashed, isNot(equals(password)));
      expect(hashed.length, equals(64)); // SHA-256 produces 64 hex characters
    });

    test('produces consistent hashes', () {
      const password = 'test123';
      final hash1 = caster.set(password);
      final hash2 = caster.set(password);

      expect(hash1, equals(hash2));
    });

    test('produces different hashes for different inputs', () {
      final hash1 = caster.set('password1');
      final hash2 = caster.set('password2');

      expect(hash1, isNot(equals(hash2)));
    });

    test('get returns hash as-is (one-way encryption)', () {
      const hash = 'abc123';
      final result = caster.get(hash);

      expect(result, equals(hash));
    });

    test('handles empty strings', () {
      final hashed = caster.set('');

      expect(hashed, isA<String>());
      expect(hashed.length, equals(64));
    });
  });

  group('IntCast', () {
    late IntCast caster;

    setUp(() {
      caster = IntCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('returns int as-is', () {
      expect(caster.get(42), equals(42));
      expect(caster.set(42), equals(42));
    });

    test('converts string to int', () {
      expect(caster.get('123'), equals(123));
      expect(caster.get('0'), equals(0));
      expect(caster.get('-42'), equals(-42));
    });

    test('converts double to int', () {
      expect(caster.get(42.9), equals(42));
      expect(caster.get(100.0), equals(100));
    });

    test('returns null for invalid strings', () {
      expect(caster.get('not a number'), isNull);
      expect(caster.get('12.34.56'), isNull);
    });
  });

  group('DoubleCast', () {
    late DoubleCast caster;

    setUp(() {
      caster = DoubleCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('returns double as-is', () {
      expect(caster.get(3.14), equals(3.14));
      expect(caster.set(2.5), equals(2.5));
    });

    test('converts string to double', () {
      expect(caster.get('3.14'), equals(3.14));
      expect(caster.get('0.5'), equals(0.5));
      expect(caster.get('-2.5'), equals(-2.5));
    });

    test('converts int to double', () {
      expect(caster.get(42), equals(42.0));
      expect(caster.get(0), equals(0.0));
    });

    test('returns null for invalid strings', () {
      expect(caster.get('not a number'), isNull);
      expect(caster.get('1.2.3'), isNull);
    });
  });

  group('BoolCast', () {
    late BoolCast caster;

    setUp(() {
      caster = BoolCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('returns bool as-is', () {
      expect(caster.get(true), isTrue);
      expect(caster.get(false), isFalse);
      expect(caster.set(true), isTrue);
    });

    test('converts int to bool', () {
      expect(caster.get(1), isTrue);
      expect(caster.get(0), isFalse);
      expect(caster.get(42), isFalse); // Only 1 is true
    });

    test('converts string to bool', () {
      expect(caster.get('true'), isTrue);
      expect(caster.get('TRUE'), isTrue);
      expect(caster.get('True'), isTrue);
      expect(caster.get('1'), isTrue);

      expect(caster.get('false'), isFalse);
      expect(caster.get('0'), isFalse);
      expect(caster.get('anything else'), isFalse);
    });
  });

  group('DateTimeCast', () {
    late DateTimeCast caster;

    setUp(() {
      caster = DateTimeCast();
    });

    test('handles null values', () {
      expect(caster.get(null), isNull);
      expect(caster.set(null), isNull);
    });

    test('returns DateTime as-is', () {
      final now = DateTime.now();
      expect(caster.get(now), equals(now));
      expect(caster.set(now), equals(now));
    });

    test('converts ISO 8601 string to DateTime', () {
      const isoString = '2024-10-09T12:00:00.000Z';
      final result = caster.get(isoString);

      expect(result, isA<DateTime>());
      expect(result!.year, equals(2024));
      expect(result.month, equals(10));
      expect(result.day, equals(9));
    });

    test('converts date string to DateTime', () {
      const dateString = '2024-10-09';
      final result = caster.get(dateString);

      expect(result, isA<DateTime>());
      expect(result!.year, equals(2024));
      expect(result.month, equals(10));
      expect(result.day, equals(9));
    });

    test('returns null for invalid date strings', () {
      expect(caster.get('not a date'), isNull);
      expect(caster.get('invalid-date-format'), isNull);
    });

    test('handles various date formats', () {
      expect(caster.get('2024-10-09T10:30:00'), isA<DateTime>());
      expect(caster.get('2024-10-09 10:30:00'), isA<DateTime>());
    });
  });

  group('Edge Cases', () {
    test('JsonCast handles arrays in JSON', () {
      final caster = JsonCast();
      const jsonString = '["not", "a", "map"]';

      // Should return null because it's not a Map
      expect(caster.get(jsonString), isNull);
    });

    test('ArrayCast handles JSON with objects', () {
      final caster = ArrayCast();
      const jsonString = '[{"key": "value"}]';
      final result = caster.get(jsonString);

      // Should convert objects to strings
      expect(result, isA<List<String>>());
    });

    test('Casters handle very large values', () {
      final jsonCaster = JsonCast();
      final arrayCaster = ArrayCast();

      // Large object
      final largeMap = Map.fromIterables(
        List.generate(1000, (i) => 'key$i'),
        List.generate(1000, (i) => 'value$i'),
      );
      expect(jsonCaster.get(jsonCaster.set(largeMap)), equals(largeMap));

      // Large array
      final largeArray = List.generate(1000, (i) => 'item$i');
      expect(arrayCaster.get(arrayCaster.set(largeArray)), equals(largeArray));
    });

    test('Casters handle special characters', () {
      final jsonCaster = JsonCast();
      final data = {
        'text':
            'Special chars: "quotes", \'apostrophes\', \n newlines, \t tabs',
        'emoji': '🎉🚀💻',
      };

      final encoded = jsonCaster.set(data);
      final decoded = jsonCaster.get(encoded);

      expect(decoded, equals(data));
    });

    test('EncryptedCast handles Unicode', () {
      final caster = EncryptedCast();
      const text = '🔒 Secure 密码 пароль';
      final hash = caster.set(text);

      expect(hash, isA<String>());
      expect(hash.length, equals(64));
    });
  });
}
