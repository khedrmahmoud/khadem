import 'khadem_model.dart';

class RelationModel<T> {
  final KhademModel<T> model;
  final Map<String, dynamic> _loaded = {};

  RelationModel(this.model);

  void set(String key, dynamic value) => _loaded[key] = value;

  dynamic get(String key) => _loaded[key];

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    for (final entry in _loaded.entries) {
      if (!model.hidden.contains(entry.key)) {
        data[entry.key] = entry.value;
      }
    }
    return data;
  }
}
