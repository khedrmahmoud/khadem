import '../../../support/helpers/date_helper.dart';
import 'khadem_model.dart';

class JsonModel<T> {
  final KhademModel<T> model;
  Map<String, dynamic> _rawData = {};

  JsonModel(this.model);

  Map<String, dynamic> get rawData => _rawData;

  void fromJson(Map<String, dynamic> json) {
    _rawData = Map<String, dynamic>.from(json); // Store raw data
    model.id = json['id'] as int?;
    for (final key in json.keys) {
      var value = json[key];
      final cast = model.casts[key];
      if (cast == DateTime && value is String) {
        value = DateTime.tryParse(value);
      } else if (cast == int && value is String) {
        value = int.tryParse(value);
      } else if (cast == double && value is String) {
        value = double.tryParse(value);
      } else if (cast == bool && value is String) {
        value = value.toLowerCase() == 'true';
      }
      model.setField(key, value);
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (model.id != null) data['id'] = model.id;

    final compinedData = <String, dynamic>{...model.rawData};

    for (final key in model.fillable) {
      if (!compinedData.containsKey(key)) {
        compinedData[key] = model.getField(key);
      }
    }
    for (final key in compinedData.keys) {
      if (!model.hidden.contains(key)) {
        final value = model.getField(key);
        data[key] = value is DateTime ? DateHelper.toResponse(value) : value;
      }
    }

    for (final key in model.appends) {
      data[key] = model.computed[key];
    }

    return data;
  }

  Map<String, dynamic> toDatabaseJson() {
    final data = <String, dynamic>{};
    for (final key in model.fillable) {
      final value = model.getField(key);
      data[key] = value is DateTime ? value.toUtc() : value;
    }
    return data;
  }
}
