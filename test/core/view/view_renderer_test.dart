import 'dart:io';
import 'package:khadem/src/core/view/renderer.dart';
import 'package:test/test.dart';

void main() {
  group('ViewRenderer Complex Expressions Tests', () {
    late ViewRenderer renderer;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('view_test_');
      await Directory('${tempDir.path}/resources/views').create(recursive: true);
      renderer = ViewRenderer(viewsDirectory: '${tempDir.path}/resources/views');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('_evaluateExpression method tests', () {
      test('should handle simple variable access', () {
        final context = {'name': 'World'};
        final result = renderer.evaluateExpression('name', context);
        expect(result, equals('World'));
      });

      test('should handle object property access', () {
        final context = {
          'user': {'name': 'Alice', 'age': 30},
        };
        final result = renderer.evaluateExpression('user.name', context);
        expect(result, equals('Alice'));
      });

      test('should handle nested object properties', () {
        final context = {
          'user': {
            'profile': {'email': 'alice@example.com'},
          },
        };
        final result = renderer.evaluateExpression('user.profile.email', context);
        expect(result, equals('alice@example.com'));
      });

      test('should handle array access with brackets', () {
        final context = {
          'items': ['apple', 'banana', 'cherry'],
        };
        final result = renderer.evaluateExpression('items[0]', context);
        expect(result, equals('apple'));
      });

      test('should handle array access with dot notation', () {
        final context = {
          'items': ['apple', 'banana'],
        };
        final result = renderer.evaluateExpression('items.0', context);
        expect(result, equals('apple'));
      });

      test('should handle list properties', () {
        final context = {
          'items': ['a', 'b', 'c'],
        };
        final result = renderer.evaluateExpression('items.length', context);
        expect(result, equals(3));
      });

      test('should handle mixed object and array access', () {
        final context = {
          'user': {
            'items': [
              {'name': 'Book', 'price': 10},
              {'name': 'Pen', 'price': 2},
            ],
          },
        };
        final result = renderer.evaluateExpression('user.items[0].name', context);
        expect(result, equals('Book'));
      });

      test('should handle null values gracefully', () {
        final context = <String, dynamic>{};
        final result = renderer.evaluateExpression('missing.value', context);
        expect(result, isNull);
      });

      test('should handle complex nested structures', () {
        final context = {
          'user': {
            'profile': {
              'personal': {
                'name': 'John',
                'address': {'city': 'NYC'},
              },
            },
            'hobbies': ['reading', 'coding', 'gaming'],
          },
        };

        expect(renderer.evaluateExpression('user.profile.personal.name', context), equals('John'));
        expect(renderer.evaluateExpression('user.profile.personal.address.city', context), equals('NYC'));
        expect(renderer.evaluateExpression('user.hobbies[0]', context), equals('reading'));
        expect(renderer.evaluateExpression('user.hobbies.length', context), equals(3));
      });

      test('should handle invalid expressions gracefully', () {
        final context = {'name': 'test'};
        final result = renderer.evaluateExpression('invalid..expression', context);
        expect(result, isNull);
      });

      test('should handle out of bounds array access', () {
        final context = {
          'items': ['a', 'b'],
        };
        final result = renderer.evaluateExpression('items[5]', context);
        expect(result, isNull);
      });
    });

   
  });
}
