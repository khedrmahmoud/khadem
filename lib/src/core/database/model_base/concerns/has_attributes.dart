import 'dart:convert';
import 'package:mysql1/mysql1.dart';

import '../../orm/casting/attribute_caster.dart';
import 'has_relations.dart';

mixin HasAttributes<T> {
  /// The model's attributes.
  final Map<String, dynamic> _attributes = {};

  /// The model's original attributes.
  final Map<String, dynamic> _original = {};

  /// Cache for computed properties.
  final Map<String, dynamic> _computedCache = {};

  /// Attributes currently being retrieved to prevent recursion.
  final Set<String> _retrieving = {};

  final Set<String> _runtimeHidden = {};
  final Set<String> _runtimeVisible = {};
  final Set<String> _runtimeAppends = {};

  /// Make attributes hidden.
  void makeHidden(List<String> attributes) {
    _runtimeHidden.addAll(attributes);
    _runtimeVisible.removeAll(attributes);
  }

  /// Make attributes visible.
  void makeVisible(List<String> attributes) {
    _runtimeVisible.addAll(attributes);
    _runtimeHidden.removeAll(attributes);
  }

  /// Append attributes.
  void append(List<String> attributes) {
    _runtimeAppends.addAll(attributes);
  }

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
  Map<String, dynamic> get appends => {};

  /// Get all of the current attributes on the model.
  Map<String, dynamic> get attributes => _attributes;

  /// Get the original attributes.
  Map<String, dynamic> get original => _original;

  /// Get an attribute from the model.
  dynamic getAttribute(String key) {
    if (_attributes.containsKey(key)) {
      return _getAttributeValue(key, _attributes[key]);
    }

    // Prevent recursion when accessing appends
    if (_retrieving.contains(key)) {
      return null;
    }
    _retrieving.add(key);

    try {
      if (appends.containsKey(key)) {
        if (_computedCache.containsKey(key)) {
          return _computedCache[key];
        }
        final value = appends[key];
        if (value is Function) {
          final result = value();
          _computedCache[key] = result;
          return result;
        }
        return value;
      }
    } finally {
      _retrieving.remove(key);
    }

    return null;
  }

  /// Get a plain attribute (not a relationship).
  dynamic _getAttributeValue(String key, dynamic value) {
    if (hasCast(key)) {
      return castAttribute(key, value);
    }
    if (value is Blob) {
      return value.toString();
    }
    return value;
  }

  /// Set a given attribute on the model.
  ///
  /// Values are stored as-is; casting to Dart types happens lazily in
  /// [getAttribute] and serialization to DB format happens in [toDatabaseMap].
  void setAttribute(String key, dynamic value) {
    _attributes[key] = value;
    _computedCache.clear();
  }

  /// Get a raw attribute without casting.
  dynamic getRawAttribute(String key, [dynamic defaultValue]) {
    return _attributes[key] ?? defaultValue;
  }

  /// Set a raw attribute without casting.
  void setRawAttribute(String key, dynamic value) {
    _attributes[key] = value;
  }

  /// Get an original attribute value.
  dynamic getOriginal(String key, [dynamic defaultValue]) {
    return _original[key] ?? defaultValue;
  }

  /// Check if the model or specific attribute is dirty.
  bool isDirty([dynamic attributes]) {
    final dirty = getDirty();
    if (attributes == null) return dirty.isNotEmpty;

    if (attributes is String) {
      return dirty.containsKey(attributes);
    }

    if (attributes is List<String>) {
      for (final key in attributes) {
        if (dirty.containsKey(key)) return true;
      }
    }

    return false;
  }

  /// Check if the model or specific attribute is clean.
  bool isClean([dynamic attributes]) => !isDirty(attributes);

  /// Check if the model has a specific attribute.
  bool hasAttribute(String key) => _attributes.containsKey(key);

  /// Check if the model has a specific original attribute.
  bool hasOriginal(String key) => _original.containsKey(key);

  /// Determine if an attribute has a cast.
  bool hasCast(String key) => casts.containsKey(key);

  /// Cast an attribute to its declared Dart type.
  dynamic castAttribute(String key, dynamic value) {
    if (value == null) return null;

    final castType = casts[key];

    // Custom AttributeCaster instances take priority.
    if (castType is AttributeCaster) return castType.get(value);

    // Non-generic types: use fast identity comparisons.
    if (castType == int) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is bool) return value ? 1 : 0;
      return int.tryParse(value.toString());
    }
    if (castType == double) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString());
    }
    if (castType == String) {
      if (value is String) return value;
      return value.toString();
    }
    if (castType == bool) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      final s = value.toString().toLowerCase();
      return s == 'true' || s == '1';
    }
    if (castType == DateTime) {
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    // Generic types: Dart's `==` operator can't parse `castType == List<X>`
    // directly (ambiguous with `<`), so use const-pattern switch.
    switch (castType) {
      case const (List<String>):
        if (value is List<String>) return value;
        if (value is List) return value.map((e) => e.toString()).toList();
        if (value is String) {
          try {
            final decoded = jsonDecode(value);
            if (decoded is List) {
              return decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }
        return <String>[];

      case const (List<dynamic>):
        if (value is List) return value;
        if (value is String) {
          try {
            return jsonDecode(value) as List;
          } catch (_) {}
        }
        return <dynamic>[];

      case const (Map<String, dynamic>):
      case const (Map):
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value);
        if (value is String) {
          try {
            final decoded = jsonDecode(value);
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
        return <String, dynamic>{};

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

  /// Get a subset of attributes.
  Map<String, dynamic> only(List<String> keys) {
    final result = <String, dynamic>{};
    for (final key in keys) {
      result[key] = getAttribute(key);
    }
    return result;
  }

  /// Get all attributes except the given keys.
  Map<String, dynamic> except(List<String> keys) {
    final result = <String, dynamic>{};
    final all = toMap();
    for (final key in all.keys) {
      if (!keys.contains(key)) {
        result[key] = all[key];
      }
    }
    return result;
  }

  /// Merge new attributes into the model.
  void mergeAttributes(Map<String, dynamic> attributes) {
    for (final key in attributes.keys) {
      setAttribute(key, attributes[key]);
    }
  }

  /// Determine if the given attribute is hidden.
  bool _isHidden(String key) {
    if (_runtimeVisible.contains(key)) return false;
    if (_runtimeHidden.contains(key)) return true;
    if (visible.isNotEmpty) return !visible.contains(key);
    return hidden.contains(key);
  }

  /// Convert the model instance to a map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    // Add attributes
    for (final key in _attributes.keys) {
      if (!_isHidden(key)) {
        map[key] = getAttribute(key);
      }
    }

    // Add appends
    final allAppendKeys = {...appends.keys, ..._runtimeAppends};
    for (final key in allAppendKeys) {
      map[key] = getAttribute(key);
    }

    // Add relations (if loaded)
    if (this is HasRelations) {
      final relations = (this as HasRelations).relations;
      for (final key in relations.keys) {
        if ((this as HasRelations).relationLoaded(key) && !_isHidden(key)) {
          map[key] = (this as HasRelations).getRelation(key);
        }
      }
    }

    return map;
  }

  Map<String, dynamic> _toJsonEncodableMap(Map<String, dynamic> map) {
    final seen = <int>{};
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      // Skip Futures as they are not JSON encodable.
      if (entry.value is Future) continue;
      // Values from toMap() are already Dart-typed (via getAttribute/castAttribute).
      // _toJsonEncodableValue handles JSON-safety (DateTime→string, Enum→name, etc.).
      // Do NOT call caster.set() here — that is for DB serialization only.
      result[entry.key] = _toJsonEncodableValue(entry.value, seen);
    }
    return result;
  }

  dynamic _toJsonEncodableValue(dynamic value, Set<int> seen) {
    if (value == null) return null;

    if (value is String || value is num || value is bool) return value;

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    if (value is Enum) {
      return value.name;
    }

    if (value is BigInt) {
      return value.toString();
    }

    if (value is Duration) {
      return value.inMicroseconds;
    }

    if (value is Blob) {
      // mysql1.Blob isn't directly JSON-encodable.
      return value.toString();
    }

    if (value is HasAttributes) {
      final id = identityHashCode(value);
      if (seen.contains(id)) return null;
      seen.add(id);
      return _toJsonEncodableValue(value.toMap(), seen);
    }

    if (value is List) {
      return value.map((e) => _toJsonEncodableValue(e, seen)).toList();
    }

    if (value is Map) {
      final out = <String, dynamic>{};
      for (final entry in value.entries) {
        out[entry.key.toString()] = _toJsonEncodableValue(entry.value, seen);
      }
      return out;
    }

    // Last resort: avoid breaking JSON encoding for custom objects.
    return value.toString();
  }

  /// Convert the model instance to JSON.
  ///
  /// This returns a map that is safe to pass to `jsonEncode()`.
  Map<String, dynamic> toJson() => _toJsonEncodableMap(toMap());

  /// Convert the model instance to a map, resolving any Future values.
  Future<Map<String, dynamic>> toMapAsync() async {
    final map = toMap();

    for (final key in map.keys) {
      if (map[key] is Future) {
        map[key] = await map[key];
      }
    }

    return map;
  }

  Future<dynamic> _resolveFuturesDeep(dynamic value) async {
    if (value is Future) {
      return _resolveFuturesDeep(await value);
    }

    if (value is HasAttributes) {
      return _resolveFuturesDeep(value.toMap());
    }

    if (value is List) {
      final resolved = <dynamic>[];
      for (final item in value) {
        resolved.add(await _resolveFuturesDeep(item));
      }
      return resolved;
    }

    if (value is Map) {
      final resolved = <dynamic, dynamic>{};
      for (final entry in value.entries) {
        resolved[entry.key] = await _resolveFuturesDeep(entry.value);
      }
      return resolved;
    }

    return value;
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    final resolved = await _resolveFuturesDeep(toMap());
    return _toJsonEncodableMap(Map<String, dynamic>.from(resolved as Map));
  }

  /// Prepare the model for database insertion/update.
  ///
  /// Serializes each attribute to its DB-storable form:
  /// - [AttributeCaster]: `get()` to normalise the Dart type, then `set()` for DB.
  /// - Type-based casts (`bool`, `DateTime`, `List`, `Map`): converted inline.
  Map<String, dynamic> toDatabaseMap() {
    final map = <String, dynamic>{};
    for (final key in _attributes.keys) {
      map[key] = _serializeForDatabase(key, _attributes[key]);
    }
    return map;
  }

  /// Converts a single attribute value to its DB-storable form.
  ///
  /// For [AttributeCaster] types the value is first normalised via `get()` so
  /// that both raw DB strings (loaded via [fromJson]) and already-typed Dart
  /// values (set via [setAttribute]) are handled correctly before calling
  /// `set()`.  This prevents double-serialisation (e.g. JSON-string → JSON
  /// string again).
  dynamic _serializeForDatabase(String key, dynamic value) {
    if (value == null || !hasCast(key)) return value;

    final castType = casts[key];

    if (castType is AttributeCaster) {
      // Normalise to Dart type first (idempotent), then serialise for DB.
      return castType.set(castType.get(value));
    }

    if (castType == bool) {
      if (value is bool) return value ? 1 : 0;
      if (value is int) return value == 0 ? 0 : 1;
      return null;
    }

    if (castType == DateTime) {
      DateTime? dt;
      if (value is DateTime) {
        dt = value;
      } else if (value is String) {
        dt = DateTime.tryParse(value);
      }
      // MySQL-compatible format: YYYY-MM-DD HH:MM:SS
      return dt
          ?.toUtc()
          .toIso8601String()
          .replaceAll('T', ' ')
          .substring(0, 19);
    }

    // Generic types: use const-pattern switch to avoid `<` ambiguity.
    switch (castType) {
      case const (List<String>):
      case const (List<dynamic>):
        if (value is List) return jsonEncode(value);
        if (value is String) return value; // already serialised from DB
        return null;

      case const (Map<String, dynamic>):
      case const (Map):
        if (value is Map) return jsonEncode(value);
        if (value is String) return value; // already serialised from DB
        return null;

      default:
        return value;
    }
  }

  /// Initialize from database record
  void fromJson(Map<String, dynamic> json) {
    _attributes.clear();
    _attributes.addAll(json);
    _computedCache.clear();
    syncOriginal();
  }
}
