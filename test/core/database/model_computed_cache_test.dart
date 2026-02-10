 import 'package:khadem/database/orm.dart';
 import 'package:test/test.dart';

class TestModel extends KhademModel<TestModel> {
  String? name;

  static int _evaluationCount = 0;

  TestModel() : super();

  @override
  TestModel newFactory(Map<String, dynamic> data) {
    return TestModel()..fromJson(data);
  }

  dynamic getField(String key) {
    switch (key) {
      case 'name':
        return name;
      default:
        return null;
    }
  }

  void setField(String key, dynamic value) {
    switch (key) {
      case 'name':
        name = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['name'];

  @override
  Map<String, dynamic> get appends => {
        'computed_name': _getComputedName,
      };

  String _getComputedName() {
    _evaluationCount++;
    final n = getAttribute('name');
    return 'Computed: ${n ?? 'Unknown'}';
  }

  static void resetCounter() {
    _evaluationCount = 0;
  }

  static int getEvaluationCount() {
    return _evaluationCount;
  }
}

void main() {
  group('Computed Property Caching', () {
    setUp(() {
      TestModel.resetCounter();
    });

    test('computed property should be cached and evaluated only once', () {
      final model = TestModel()..fromJson({'name': 'Test'});

      // First access - should evaluate
      expect(model.getAttribute('computed_name'), 'Computed: Test');
      expect(TestModel.getEvaluationCount(), 1);

      // Second access - should use cache
      expect(model.getAttribute('computed_name'), 'Computed: Test');
      expect(TestModel.getEvaluationCount(), 1); // Should still be 1

      // Third access - should still use cache
      expect(model.getAttribute('computed_name'), 'Computed: Test');
      expect(TestModel.getEvaluationCount(), 1); // Should still be 1
    });

    test('cache should be cleared when model data changes', () {
      final model = TestModel()..fromJson({'name': 'Test'});

      // First access
      expect(model.getAttribute('computed_name'), 'Computed: Test');
      expect(TestModel.getEvaluationCount(), 1);

      // Change model data
      model.fromJson({'name': 'Updated'});

      // Access again - should re-evaluate
      expect(model.getAttribute('computed_name'), 'Computed: Updated');
      expect(TestModel.getEvaluationCount(), 2); // Should be 2 now
    });

    test('toJson should only evaluate computed properties once', () {
      final model = TestModel()..fromJson({'name': 'Test'});

      // Call toJson multiple times
      final json1 = model.toJson();
      final json2 = model.toJson();

      expect(json1['computed_name'], 'Computed: Test');
      expect(json2['computed_name'], 'Computed: Test');
      expect(
        TestModel.getEvaluationCount(),
        1,
      ); // Should only be evaluated once total
    });
  });
}
