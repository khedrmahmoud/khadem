import 'khadem_model.dart';

class RelationModel<T> {
  final KhademModel<T> model;
  final Map<String, dynamic> _loaded = {};

  RelationModel(this.model);

  void set(String key, dynamic value) => _loaded[key] = value;

  dynamic get(String key) => _loaded[key];

  bool isLoaded(String key) => _loaded.containsKey(key);

  /// Get all loaded relations and counts
  Map<String, dynamic> getAllLoaded() => Map.from(_loaded);

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    for (final entry in _loaded.entries) {
      if (!model.hidden.contains(entry.key)) {
        data[entry.key] = entry.value;
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    final data = <String, dynamic>{};
    for (final entry in _loaded.entries) {
      if (!model.hidden.contains(entry.key)) {
        final value = entry.value;
        if (value is KhademModel) {
          data[entry.key] = await value.toJsonAsync();
        } else if (value is List<KhademModel>) {
          data[entry.key] =
              await Future.wait(value.map((m) => m.toJsonAsync()));
        } else if (value is Future<KhademModel>) {
          final resolved = await value;
          data[entry.key] = await resolved.toJsonAsync();
        } else if (value is Future<List<KhademModel>>) {
          final resolvedList = await value;
          data[entry.key] =
              await Future.wait(resolvedList.map((m) => m.toJsonAsync()));
        } else {
          data[entry.key] = value;
        }
      }
    }
    return data;
  }

  void clear() => _loaded.clear();
}
