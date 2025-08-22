class ViewCache {
  final Map<String, String> _cache = {};

  void set(String path, String content) => _cache[path] = content;
  String? get(String path) => _cache[path];
  bool exists(String path) => _cache.containsKey(path);
  void clear() => _cache.clear();
}
