import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

class KhademPackageMetadata {
  const KhademPackageMetadata({
    required this.version,
    required this.sdkConstraint,
    required this.documentation,
    required this.releaseDate,
  });

  final String version;
  final String sdkConstraint;
  final String documentation;
  final String releaseDate;
  String get author => 'Khedr Mahmoud';
}

class KhademPackageMetadataLoader {
  static KhademPackageMetadata? _cached;

  static KhademPackageMetadata loadSync() {
    return _cached ??= _loadSync();
  }

  static KhademPackageMetadata _loadSync() {
    final pubspec = _tryLoadKhademPubspecYamlSync();

    final version = _string(pubspec, 'version') ?? 'unknown';

    final environment = pubspec['environment'];
    final sdkConstraint = environment is YamlMap
        ? (_string(environment, 'sdk') ?? 'unknown')
        : 'unknown';

    final documentation = _string(pubspec, 'documentation') ?? 'unknown';
    final releaseDate = _string(pubspec, 'release_date') ?? 'unknown';

    return KhademPackageMetadata(
      version: version,
      sdkConstraint: sdkConstraint,
      documentation: documentation,
      releaseDate: releaseDate,
    );
  }

  static YamlMap _tryLoadKhademPubspecYamlSync() {
    final packageRoot = _tryResolveKhademPackageRootSync();
    if (packageRoot == null) {
      return YamlMap();
    }

    final pubspecFile = File(_joinUriPath(packageRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return YamlMap();
    }

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    return yaml is YamlMap ? yaml : YamlMap();
  }

  static Uri? _tryResolveKhademPackageRootSync() {
    final configFile = _findUpwardsSync('.dart_tool/package_config.json');
    if (configFile == null) {
      return null;
    }

    final raw = configFile.readAsStringSync();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final packages = decoded['packages'];
    if (packages is! List) {
      return null;
    }

    final khadem = packages.cast<dynamic>().whereType<Map>().firstWhere(
      (p) => p['name'] == 'khadem',
      orElse: () => const {},
    );

    final rootUriValue = khadem['rootUri'];
    if (rootUriValue is! String) {
      return null;
    }

    final base = configFile.uri;
    return base.resolve(rootUriValue);
  }

  static File? _findUpwardsSync(String relativePath) {
    Directory current = Directory.current;

    while (true) {
      final candidate = File(
        '${current.path}${Platform.pathSeparator}$relativePath',
      );
      if (candidate.existsSync()) {
        return candidate;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }
      current = parent;
    }
  }

  static String _joinUriPath(Uri base, String path) {
    // Ensure directory-like base.
    final normalizedBase = base.toString().endsWith('/')
        ? base
        : Uri.parse('${base.toString()}/');
    return normalizedBase.resolve(path).toFilePath();
  }

  static String? _string(YamlMap map, String key) {
    final value = map[key];
    return value is String ? value : null;
  }
}
