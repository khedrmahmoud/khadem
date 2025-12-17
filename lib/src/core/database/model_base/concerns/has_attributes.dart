import '../../../../contracts/database/query_builder_interface.dart';
import '../../orm/casting/attribute_caster.dart';
import '../../support/helpers/date_helper.dart';
import '../khadem_model.dart';

mixin HasAttributes<T> on KhademModel<T> {
  /// The model's attributes.
  final Map<String, dynamic> _attributes = {};

  /// The model's original attributes.
  final Map<String, dynamic> _original = {};

  /// The attributes that have been changed.
  final Map<String, dynamic> _changes = {};

  /// The attributes that should be cast to native types.
  Map<String, dynamic> get casts => {};

  /// The attributes that are mass assignable.
  List<String> get fillable => [];

  /// The attributes that aren't mass assignable.
  List<String> get guarded => ['*'];

  /// The attributes that should be hidden for serialization.
  List<String> get hidden => [];

  /// The attributes that should be visible in serialization.
  List<String> get visible => [];

  /// The accessors to append to the model's array form.
  List<String> get appends => [];

  /// Get all of the current attributes on the model.
  Map<String, dynamic> get attributes => _attributes;

  /// Get the original attributes.
  Map<String, dynamic> get original => _original;

  /// Get an attribute from the model.
  dynamic getAttribute(String key) {
    if (_attributes.containsKey(key)) {
      return _getAttributeValue(key, _attributes[key]);
    }

    // Check for accessor (e.g., getFirstNameAttribute)
    // Dart doesn't support dynamic method dispatch by name easily without reflection.
    // We'll rely on the `computed` map or explicit getters in the concrete class.
    
    return null;
  }

  /// Get a plain attribute (not a relationship).
  dynamic _getAttributeValue(String key, dynamic value) {
    if (hasCast(key)) {
      return castAttribute(key, value);
    }
    return value;
  }

  /// Set a given attribute on the model.
  void setAttribute(String key, dynamic value) {
    // Check for mutator (e.g., setFirstNameAttribute) - skipped for now due to reflection limits
    
    // Handle casting for setting
    if (hasCast(key)) {
      final caster = casts[key];
      if (caster is AttributeCaster) {
        value = caster.set(value);
      }
    }

    _attributes[key] = value;
  }

  /// Determine if an attribute has a cast.
  bool hasCast(String key) => casts.containsKey(key);

  /// Cast an attribute to a native Dart type.
  dynamic castAttribute(String key, dynamic value) {
    if (value == null) return null;

    final castType = casts[key];

    if (castType is AttributeCaster) {
      return castType.get(value);
    }

    switch (castType) {
      case int:
        return int.tryParse(value.toString());
      case double:
        return double.tryParse(value.toString());
      case String:
        return value.toString();
      case bool:
        if (value is bool) return value;
        if (value is int) return value == 1;
        return value.toString().toLowerCase() == 'true';
      case DateTime:
        if (value is DateTime) return value;
        return DateTime.tryParse(value.toString());
      case const (List<String>):
      case const (List<dynamic>):
      case const (Map<String, dynamic>):
        // JSON casting would go here if not using AttributeCaster
        return value;
      default:
        return value;
    }
  }

  /// Sync the original attributes with the current.
  void syncOriginal() {
    _original.clear();
    _original.addAll(_attributes);
  }

  /// Get the attributes that have been changed since the last sync.
  Map<String, dynamic> getDirty() {
    final dirty = <String, dynamic>{};

    for (final key in _attributes.keys) {
      if (!_original.containsKey(key) || _original[key] != _attributes[key]) {
        dirty[key] = _attributes[key];
      }
    }

    return dirty;
  }

  /// Fill the model with an array of attributes.
  T fill(Map<String, dynamic> attributes) {
    for (final key in attributes.keys) {
      if (isFillable(key)) {
        setAttribute(key, attributes[key]);
      }
    }
    return this as T;
  }

  /// Force fill the model with an array of attributes.
  T forceFill(Map<String, dynamic> attributes) {
    for (final key in attributes.keys) {
      setAttribute(key, attributes[key]);
    }
    return this as T;
  }

  /// Determine if the given attribute may be mass assigned.
  bool isFillable(String key) {
    if (fillable.contains('*')) return true;
    if (fillable.contains(key)) return true;
    if (guarded.contains('*')) return false;
    return guarded.isEmpty || !guarded.contains(key);
  }

  /// Convert the model instance to a map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    
    // Add attributes
    for (final key in _attributes.keys) {
      if (!hidden.contains(key)) {
        map[key] = getAttribute(key);
      }
    }

    // Add appends
    for (final key in appends) {
      map[key] = getAttribute(key);
    }

    // Add relations (if loaded)
    // This requires HasRelations mixin
    if (this is HasRelations) {
      final relations = (this as HasRelations).relations;
      for (final key in relations.keys) {
        if ((this as HasRelations).relationLoaded(key) && !hidden.contains(key)) {
          map[key] = (this as HasRelations).getRelation(key);
        }
      }
    }

    return map;
  }

  /// Convert the model instance to JSON.
  Map<String, dynamic> toJson() => toMap();

  /// Prepare the model for database insertion/update.
  Map<String, dynamic> toDatabaseMap() {
    final map = <String, dynamic>{};
    
    for (final key in _attributes.keys) {
      // Skip appends or computed values that aren't in the database
      // This is a simplified check; ideally we check against schema or assume attributes set via setAttribute are columns
      
      var value = _attributes[key];
      
      // Handle casting for database
      if (hasCast(key)) {
        final caster = casts[key];
        if (caster is AttributeCaster) {
          value = caster.set(value);
        } else if (value is DateTime) {
          value = value.toUtc().toIso8601String();
        } else if (value is bool) {
          value = value ? 1 : 0;
        }
      }
      
      map[key] = value;
    }
    
    return map;
  }
  
  /// Initialize from database record
  void fromJson(Map<String, dynamic> json) {
    _attributes.clear();
    _attributes.addAll(json);
    syncOriginal();
  }
}

// Forward declaration for HasRelations check
mixin HasRelations<T> on KhademModel<T> {
  Map<String, dynamic> get relations;
  bool relationLoaded(String key);
  dynamic getRelation(String key);
}
