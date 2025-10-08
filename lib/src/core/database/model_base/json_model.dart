import 'package:mysql1/mysql1.dart';

import '../../../support/helpers/date_helper.dart';
import 'khadem_model.dart';

class JsonModel<T> {
  final KhademModel<T> model;
  Map<String, dynamic> _rawData = {};

  JsonModel(this.model);

  Map<String, dynamic> get rawData => _rawData;

  /// Check if an attribute is mass assignable
  /// 
  /// An attribute is fillable if:
  /// - `fillable` list is defined and contains the attribute, OR
  /// - `fillable` list is empty AND attribute is not in `guarded` list
  bool isFillable(String key) {
    // If fillable is specified, only those attributes are fillable
    if (model.fillable.isNotEmpty) {
      return model.fillable.contains(key);
    }
    
    // If fillable is empty, everything except guarded is fillable
    return !model.guarded.contains(key);
  }

  void fromJson(Map<String, dynamic> json, {bool force = true}) {
    _rawData = Map<String, dynamic>.from(json); // Store raw data
    
    // Handle id separately, respecting fillable/guarded unless force=true
    if (json.containsKey('id')) {
      if (force || isFillable('id')) {
        model.id = model.id ?? json['id'] as int?;
      }
    }
    
    for (final key in json.keys) {
      // Skip id as we already handled it
      if (key == 'id') continue;
      
      // Skip non-fillable attributes unless force is true
      if (!force && !isFillable(key)) {
        continue;
      }
      
      var value = json[key];
      final cast = model.casts[key];
      if (cast == DateTime && value is String) {
        value = DateTime.tryParse(value);
      } else if (cast == int && value is String) {
        value = int.tryParse(value);
      } else if (cast == double && value is String) {
        value = double.tryParse(value);
      } else if (cast == bool) {
        if (value is int) {
          value = value == 1;
        } else if (value is String) {
          value = value.toLowerCase() == 'true';
        }
      } else if (value is Blob) {
        value = value.toString();
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
      // Skip hidden and protected attributes
      if (model.hidden.contains(key) || model.protected.contains(key)) {
        continue;
      }
      final value = model.getField(key);
      data[key] = value is DateTime ? DateHelper.toResponse(value) : value;
    }

    // Note: Computed properties are now handled in KhademModel.toJson()
    // after relations are loaded

    return data;
  }

  /// Async version of toJson() that properly handles async computed properties
  /// 
  /// This method awaits async computed properties before adding them to JSON.
  /// Use this when your model has async functions in the `computed` map.
  Future<Map<String, dynamic>> toJsonAsync() async {
    final data = <String, dynamic>{};
    if (model.id != null) data['id'] = model.id;

    final compinedData = <String, dynamic>{...model.rawData};

    for (final key in model.fillable) {
      if (!compinedData.containsKey(key)) {
        compinedData[key] = model.getField(key);
      }
    }
    for (final key in compinedData.keys) {
      // Skip hidden and protected attributes
      if (model.hidden.contains(key) || model.protected.contains(key)) {
        continue;
      }
      final value = model.getField(key);
      data[key] = value is DateTime ? DateHelper.toResponse(value) : value;
    }

    // Note: Computed properties are now handled in KhademModel.toJsonAsync()
    // after relations are loaded

    return data;
  }

  Map<String, dynamic> toDatabaseJson() {
    final data = <String, dynamic>{};
    for (final key in model.fillable) {
      final value = model.getField(key);
      if (value == null) continue;
      data[key] = value is DateTime ? value.toUtc() : value;
    }
    return data;
  }
}
