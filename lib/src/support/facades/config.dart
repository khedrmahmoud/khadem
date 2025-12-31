import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/contracts/config/config_contract.dart';
/// Facade for application configuration.
///
/// Use `Config.get`, `Config.section`, and related helpers to access
/// configuration values without resolving the config service manually.
class Config {
  static ConfigInterface get _instance => Khadem.make<ConfigInterface>();

  static T? get<T>(String key, [T? defaultValue]) =>
      _instance.get<T>(key, defaultValue);

  static T getOrFail<T>(String key) => _instance.getOrFail<T>(key);

  static void set(String key, dynamic value) => _instance.set(key, value);

  static void push(String key, dynamic value) => _instance.push(key, value);

  static void pop(String key) => _instance.pop(key);

  static bool has(String key) => _instance.has(key);

  static Map<String, dynamic> all() => _instance.all();

  static Map<String, dynamic>? section(String name) => _instance.section(name);

  static void reload() => _instance.reload();

  static void loadFromRegistry(Map<String, Map<String, dynamic>> registry) =>
      _instance.loadFromRegistry(registry);
}
