import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:test/test.dart';

class TestModel extends KhademModel<TestModel> {
  String? name;

  @override
  TestModel newFactory(Map<String, dynamic> data) =>
      TestModel()..name = data['name'];

  @override
  List<String> get initialAppends => ['test_attr'];

  @override
  List<String> get initialHidden => ['secret'];

  @override
  Map<String, dynamic> get computed => {
        'test_attr': () => 'computed_value',
      };

  @override
  dynamic getField(String key) => key == 'name' ? name : null;

  @override
  void setField(String key, dynamic value) {
    if (key == 'name') name = value;
  }
}

void main() {
  test('append methods should work with getters', () {
    final model = TestModel()..name = 'test';

    // Test append
    model.append(['test_attr']);
    expect(model.appends, contains('test_attr'));
    expect(model.hasAppended('test_attr'), isTrue);

    // Test appendAttribute
    model.appendAttribute('another_attr');
    expect(model.appends, contains('another_attr'));

    // Test setAppended
    model.setAppended('custom_attr');
    expect(model.appends, contains('custom_attr'));

    // Test makeHidden and makeVisible
    expect(model.hidden, contains('secret'));
    model.makeHidden(['name']);
    expect(model.hidden, contains('name'));
    model.makeVisible(['name']);
    expect(model.hidden, isNot(contains('name')));
  });
}
