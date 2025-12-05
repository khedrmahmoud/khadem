/// Manages request parameters and custom attributes.
///
/// Handles path parameters from routing and custom
/// attributes set during request processing.
class RequestParams {
  final Map<String, String> _pathParams;
  final Map<String, dynamic> _attributes;

  RequestParams(this._pathParams, this._attributes);

  // Path Parameters

  /// Gets all path parameters.
  Map<String, String> get all => Map.unmodifiable(_pathParams);

  /// Gets a path parameter.
  String? param(String key) => _pathParams[key];

  /// Gets path parameter with default.
  String paramOr(String key, String defaultValue) =>
      _pathParams[key] ?? defaultValue;

  /// Gets typed path parameter.
  T? paramTyped<T>(String key) {
    final value = _pathParams[key];
    if (value == null) return null;

    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return (value == 'true' || value == '1') as T?;
    if (T == String) return value as T?;

    return null;
  }

  /// Gets path parameter as int.
  int? paramInt(String key) => paramTyped<int>(key);

  /// Gets path parameter as double.
  double? paramDouble(String key) => paramTyped<double>(key);

  /// Gets path parameter as bool.
  bool paramBool(String key) => paramTyped<bool>(key) ?? false;

  /// Sets a path parameter.
  void setParam(String key, String value) {
    _pathParams[key] = value;
  }

  /// Removes a path parameter.
  void removeParam(String key) {
    _pathParams.remove(key);
  }

  /// Checks if path parameter exists.
  bool hasParam(String key) => _pathParams.containsKey(key);

  /// Checks if multiple path parameters exist.
  bool hasAllParams(List<String> keys) => keys.every(hasParam);

  /// Gets path parameter keys.
  Iterable<String> get paramKeys => _pathParams.keys;

  /// Gets path parameter values.
  Iterable<String> get paramValues => _pathParams.values;

  /// Gets path parameters count.
  int get paramCount => _pathParams.length;

  /// Clears all path parameters.
  void clearParams() {
    _pathParams.clear();
  }

  // Custom Attributes

  /// Gets a custom attribute.
  T? attribute<T>(String key) {
    final value = _attributes[key];
    return value is T ? value : null;
  }

  /// Gets attribute with default.
  T attributeOr<T>(String key, T defaultValue) {
    final value = _attributes[key];
    return value is T ? value : defaultValue;
  }

  /// Gets all custom attributes.
  Map<String, dynamic> get attributes => Map.unmodifiable(_attributes);

  /// Sets a custom attribute.
  void setAttribute(String key, dynamic value) {
    _attributes[key] = value;
  }

  /// Removes a custom attribute.
  void removeAttribute(String key) {
    _attributes.remove(key);
  }

  /// Checks if attribute exists.
  bool hasAttribute(String key) => _attributes.containsKey(key);

  /// Checks if multiple attributes exist.
  bool hasAllAttributes(List<String> keys) => keys.every(hasAttribute);

  /// Gets attribute keys.
  Iterable<String> get attributeKeys => _attributes.keys;

  /// Gets attribute values.
  Iterable<dynamic> get attributeValues => _attributes.values;

  /// Gets attributes count.
  int get attributeCount => _attributes.length;

  /// Clears all attributes.
  void clearAttributes() {
    _attributes.clear();
  }

  /// Gets all parameters and attributes combined.
  Map<String, dynamic> allData() {
    final map = <String, dynamic>{..._pathParams};
    map.addAll(_attributes);
    return map;
  }

  /// Converts to map.
  Map<String, dynamic> toMap() => allData();
}
