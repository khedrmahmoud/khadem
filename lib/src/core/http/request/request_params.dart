/// Handles parameter management for HTTP requests.
/// Includes path parameters, query parameters, and custom attributes.
class RequestParams {
  final Map<String, String> _pathParams;
  final Map<String, dynamic> _attributes;

  RequestParams(this._pathParams, this._attributes);

  /// Path parameters extracted from the router.
  Map<String, String> get pathParams => Map.unmodifiable(_pathParams);

  /// Custom runtime attributes like `user`, `session`, etc.
  Map<String, dynamic> get attributes => _attributes;

  /// Gets a path parameter by key.
  String? param(String key) {
    return _pathParams[key];
  }

  /// Gets a path parameter with a default value.
  String paramWithDefault(String key, String defaultValue) {
    return _pathParams[key] ?? defaultValue;
  }

  /// Sets a path parameter.
  void setParam(String key, String value) {
    _pathParams[key] = value;
  }

  /// Removes a path parameter.
  void removeParam(String key) {
    _pathParams.remove(key);
  }

  /// Gets a custom attribute by key.
  T? attribute<T>(String key) {
    return _attributes[key] as T?;
  }

  /// Sets a custom attribute.
  void setAttribute(String key, dynamic value) {
    _attributes[key] = value;
  }

  /// Removes a custom attribute.
  void removeAttribute(String key) {
    _attributes.remove(key);
  }

  /// Checks if a path parameter exists.
  bool hasParam(String key) {
    return _pathParams.containsKey(key);
  }

  /// Checks if a custom attribute exists.
  bool hasAttribute(String key) {
    return _attributes.containsKey(key);
  }

  /// Clears all path parameters.
  void clearParams() {
    _pathParams.clear();
  }

  /// Clears all custom attributes.
  void clearAttributes() {
    _attributes.clear();
  }

  /// Gets all parameter keys.
  List<String> get paramKeys => _pathParams.keys.toList();

  /// Gets all attribute keys.
  List<String> get attributeKeys => _attributes.keys.toList();
}
