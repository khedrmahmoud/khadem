import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:test/test.dart';

class TestModel extends KhademModel<TestModel> {
  @override
  TestModel newFactory(Map<String, dynamic> data) {
    final m = TestModel();
    m.fromJson(data);
    return m;
  }

  @override
  Map<String, dynamic> get appends => {'test_attr': 'computed_value'};

  @override
  List<String> get hidden => ['secret'];
}

void main() {
  test('append methods should work with getters', () {
    final model = TestModel();
    model.setAttribute('name', 'test');
    model.setAttribute('secret', 'hidden_value');

    // Test initial appends
    expect(model.toMap(), contains('test_attr'));
    expect(model.toMap()['test_attr'], equals('computed_value'));

    // Test makeHidden
    expect(model.toMap().containsKey('secret'), isFalse);
    model.makeVisible(['secret']);
    expect(model.toMap().containsKey('secret'), isTrue);

    model.makeHidden(['name']);
    expect(model.toMap().containsKey('name'), isFalse);
  });
}
