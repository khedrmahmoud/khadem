import 'package:khadem/khadem.dart';
import 'package:test/test.dart';

void main() {
  group('Container Helpers', () {
    setUp(() {
      // Reset container
      ContainerProvider.instance.flush();
    });

    test('app() returns container when no type provided', () {
      final container = app();
      expect(container, isA<ContainerInterface>());
    });

    test('app<T>() resolves service', () {
      final container = app();
      container.instance<String>('test_service');

      final result = app<String>();
      expect(result, equals('test_service'));
    });

    test('resolve<T>() resolves service', () {
      final container = app();
      container.instance<int>(123);

      final result = resolve<int>();
      expect(result, equals(123));
    });
  });
}
