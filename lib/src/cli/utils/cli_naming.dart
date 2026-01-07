class CliNaming {
  static String normalizePathInput(String input) {
    return input.trim().replaceAll('\\', '/');
  }

  static ({String folder, String name}) splitFolderAndName(String input) {
    final normalized = normalizePathInput(input);
    final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      return (folder: '', name: '');
    }

    if (parts.length == 1) {
      return (folder: '', name: parts.single);
    }

    final folder = parts.sublist(0, parts.length - 1).join('/');
    final name = parts.last;
    return (folder: folder, name: name);
  }

  static String ensureSuffix(String name, String suffix) {
    if (name.endsWith(suffix)) return name;
    return '$name$suffix';
  }

  static String toPascalCase(String input) {
    if (input.isEmpty) return input;

    final normalized = input
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'__+'), '_');

    return normalized
        .split('_')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join();
  }

  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    final withUnderscores = input
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (m) => '${m[1]}_${m[2]}',
        );

    return withUnderscores.toLowerCase();
  }
}
