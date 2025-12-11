import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/contracts/env/env_interface.dart';

class Env {
  static EnvInterface get _instance => Khadem.make<EnvInterface>();

  static String? get(String key) => _instance.get(key);

  static String getOrDefault(String key, String defaultValue) =>
      _instance.getOrDefault(key, defaultValue);

  static String getOrFail(String key) => _instance.getOrFail(key);

  static bool getBool(String key, {bool defaultValue = false}) =>
      _instance.getBool(key, defaultValue: defaultValue);

  static int getInt(String key, {int defaultValue = 0}) =>
      _instance.getInt(key, defaultValue: defaultValue);

  static double getDouble(String key, {double defaultValue = 0.0}) =>
      _instance.getDouble(key, defaultValue: defaultValue);

  static List<String> getList(
    String key, {
    String separator = ',',
    List<String> defaultValue = const [],
  }) =>
      _instance.getList(key, separator: separator, defaultValue: defaultValue);

  static void set(String key, String value) => _instance.set(key, value);

  static bool has(String key) => _instance.has(key);

  static Map<String, String> all() => _instance.all();

  static List<String> get loadedFiles => _instance.loadedFiles;

  static void loadFromFile(String path) => _instance.loadFromFile(path);

  static void clear() => _instance.clear();

  static List<String> validateRequired(List<String> requiredKeys) =>
      _instance.validateRequired(requiredKeys);
}
