import 'body_parser.dart';
import 'uploaded_file.dart';

/// Provides convenient input access for request body, files, and query data.
class RequestInput {
  final BodyParser _bodyParser;
  final Map<String, String> _queryParams;

  RequestInput(this._bodyParser, this._queryParams);

  /// Adds or updates a value in the request body.
  void add(String key, dynamic value) {
    _bodyParser.add(key, value);
  }

  /// Removes a value from the request body.
  void remove(String key) {
    _bodyParser.remove(key);
  }

  /// Merges values into the request body.
  void merge(Map<String, dynamic> values) {
    _bodyParser.merge(values);
  }

  /// Gets a value from body or query parameters.
  dynamic get(String key, [dynamic defaultValue]) {
    // First try body
    if (_bodyParser.body != null && _bodyParser.body!.containsKey(key)) {
      return _bodyParser.body![key];
    }
    // Then try query
    if (_queryParams.containsKey(key)) {
      return _queryParams[key];
    }
    return defaultValue;
  }

  /// Gets typed value from body or query.
  T? typed<T>(String key, [T? defaultValue]) {
    final value = get(key);
    if (value is T) return value;
    return defaultValue;
  }

  /// Gets string value.
  String? string(String key, [String? defaultValue]) =>
      typed<String>(key, defaultValue);

  /// Gets integer value.
  int? integer(String key, [int? defaultValue]) {
    final value = get(key);
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return defaultValue;
  }

  /// Gets double value.
  double? doubleValue(String key, [double? defaultValue]) {
    final value = get(key);
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return defaultValue;
  }

  /// Gets boolean value.
  bool boolean(String key, [bool defaultValue = false]) {
    final value = get(key);
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return defaultValue;
  }

  /// Gets list value.
  List<T>? list<T>(String key) {
    final value = get(key);
    if (value is List) {
      return value.cast<T>();
    }
    return null;
  }

  /// Gets map value.
  Map<String, dynamic>? map(String key) {
    final value = get(key);
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  /// Checks if key exists in body or query.
  bool has(String key) {
    return (_bodyParser.body != null && _bodyParser.body!.containsKey(key)) ||
        _queryParams.containsKey(key);
  }

  /// Checks if multiple keys exist.
  bool hasAll(List<String> keys) => keys.every(has);

  /// Checks if any of the keys exist.
  bool hasAny(List<String> keys) => keys.any(has);

  /// Gets multiple values at once.
  Map<String, dynamic> only(List<String> keys) {
    return {
      for (final key in keys)
        if (has(key)) key: get(key),
    };
  }

  /// Gets all values except specified keys.
  Map<String, dynamic> except(List<String> keys) {
    final result = <String, dynamic>{};

    // Add from body
    if (_bodyParser.body != null) {
      for (final entry in _bodyParser.body!.entries) {
        if (!keys.contains(entry.key)) {
          result[entry.key] = entry.value;
        }
      }
    }

    // Add from query
    for (final entry in _queryParams.entries) {
      if (!keys.contains(entry.key) && !result.containsKey(entry.key)) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  /// Gets file by field name.
  UploadedFile? file(String fieldName) => _bodyParser.file(fieldName);

  /// Gets all files.
  Map<String, UploadedFile>? get files => _bodyParser.files;

  /// Checks if file was uploaded.
  bool hasFile(String fieldName) => _bodyParser.hasFile(fieldName);

  /// Gets all files with a field name.
  List<UploadedFile> filesByName(String fieldName) =>
      _bodyParser.filesByName(fieldName);

  /// Gets all input as map (body + query).
  Map<String, dynamic> all() {
    final result = Map<String, dynamic>.from(_queryParams);
    if (_bodyParser.body != null) {
      result.addAll(_bodyParser.body!);
    }
    return result;
  }

  /// Gets input keys.
  Set<String> keys() {
    final keys = <String>{..._queryParams.keys};
    if (_bodyParser.body != null) {
      keys.addAll(_bodyParser.body!.keys);
    }
    return keys;
  }

  /// Gets input values.
  Iterable<dynamic> values() {
    final result = <dynamic>[..._queryParams.values];
    if (_bodyParser.body != null) {
      result.addAll(_bodyParser.body!.values);
    }
    return result;
  }

  /// Converts input to map.
  Map<String, dynamic> toMap() => all();
}
