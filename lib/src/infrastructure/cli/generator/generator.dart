// lib/src/support/cli/generator/generator.dart
import 'dart:io';

class Generator {
  static Future<void> createProject(String name) async {
    final base = Directory(name);
    if (await base.exists()) throw Exception('Directory $name already exists');

    // 📁 Folders
    final folders = [
      'app/Http/Controllers',
      'app/Http/Middleware',
      'app/Console',
      'app/Exceptions',
      'app/Models',
      'app/Providers',
      'bootstrap',
      'config/development',
      'config/production',
      'core',
      'lang/en',
      'lang/ar',
      'resources/views',
      'routes',
      'database/migrations',
      'database/seeders',
      'public/assets',
      'storage/logs',
      'storage/cache',
      'bin',
    ];
    await Future.wait(folders.map((f) => _createDir('$name/$f')));

    // 📄 Files
    final files = {
      'pubspec.yaml': _pubspecTemplate(name),
      '.gitignore': _gitignore,
      '.env': _env,
      'config/app.dart': _appConfig,
      'config/app.json': _appJson,
      'config/development/logging.json': _loggingJson(true),
      'config/production/logging.json': _loggingJson(false),
      'config/cache.dart': _cacheConfig,
      'config/queue.dart': _queueConfig,
      'config/database.dart': _databaseConfig,
      'lang/en/validation.json': _langValidationEn,
      'lang/ar/validation.json': _langValidationAr,
      'lang/ar/fields.json': _langFieldsAr,
      'lang/en/fields.json': _langFieldsEn,
      'routes/web.dart': _webRoutes,
      'bootstrap/app.dart': _bootstrapApp,
      'core/Kernel.dart': _kernel,
      'app/Http/Controllers/HomeController.dart': _homeController,
      'bin/server.dart': _server(name),
      'Dockerfile': _dockerfile,
    };

    await Future.wait(
        files.entries.map((e) => _createFile('$name/${e.key}', e.value)));
  }

  static Future<void> _createDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  static Future<void> _createFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  // Templates

  static String _pubspecTemplate(String name) => '''
name: $name
description: A new Khadem Dart project.
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  ignite_dart: ^1.0.0
  dotenv: ^4.0.1
  mysql1: ^0.20.0
  redis: ^3.1.0
  path: ^1.8.3
''';

  static const _gitignore = '''
.dart_tool/
build/
pubspec.lock
.env
storage/logs/*
''';

  static const _env = '''
APP_NAME=KhademApp
APP_ENV=development
APP_PORT=8080
''';

  static const _appConfig = '''
import 'package:ignite_dart/ignite_dart.dart';

class AppConfig {
  final envSystem = Khadem.env;
  String get name => envSystem.getOrDefault('APP_NAME', 'Khadem App');
  String get env => envSystem.getOrDefault('APP_ENV', 'production');
  bool get debug => env == 'development';
}
''';

  static const _appJson = '''
{
  "name": "KhademApp",
  "env": "development"
}
''';

  static String _loggingJson(bool dev) => '''
{
  "default": "app",
  "minimum_level": "debug",
  "handlers": {
    "file": {
      "enabled": ${!dev},
      "path": "storage/logs/app.log",
      "format_json": true,
      "rotate_on_size": true,
      "rotate_daily": false,
      "max_size": 5242880,
      "max_backups": 5
    },
    "console": {
      "enabled": true,
      "colorize": $dev
    }
  }
}
''';

  static const _cacheConfig = '''
final Map<String, dynamic> cache = {
  'driver': 'file',
  'path': 'storage/cache',
};
''';

  static const _queueConfig = '''
final Map<String, dynamic> queue = {
  'driver': 'sync',
};
''';

  static const _databaseConfig = '''
final Map<String, dynamic> database = {
  'driver': 'mysql',
  'host': 'localhost',
  'port': 3306,
  'database': 'ignite_db',
  'username': 'root',
  'password': '',
};
''';

  static const _langValidationEn = '''
{
  "required": "The :field field is required.",
  "email": "The :field must be a valid email address."
}
''';

  static const _langValidationAr = '''
{
  "required": "حقل :field مطلوب.",
  "email": "يجب أن يكون :field بريدًا إلكترونيًا صالحًا."
}
''';

  static const _langFieldsEn = '''
{
  "email": "Email",
  "password": "Password",
  "name": "Name"
}
''';

  static const _langFieldsAr = '''
{
  "email": "البريد الإلكتروني",
  "password": "كلمة المرور",
  "name": "الاسم"
}
''';

  static const _webRoutes = '''
import 'package:ignite_dart/ignite_dart.dart';
import '../app/Http/Controllers/HomeController.dart';

void registerRoutes(Server server) {
  server.get('/', HomeController().index);
}
''';

  static const _homeController = '''
import 'package:ignite_dart/ignite_dart.dart';

class HomeController {
  void index(Request req, Response res) {
    res.sendJson({'message': 'Welcome to Khadem Dart Framework!'});
  }
}
''';

  static const _bootstrapApp = '''
import 'package:ignite_dart/ignite_dart.dart';
import '../config/app.dart';

Future<void> bootstrap() async {
  final container = Khadem.container;
  await Khadem.boot();
  container.singleton<AppConfig>((c) => AppConfig());
}
''';

  static String _server(String name) => '''
import 'package:ignite_dart/ignite_dart.dart';
import '../routes/web.dart';
import '../bootstrap/app.dart';

Future<void> main(List<String> args) async {
  final portIndex = args.indexOf('--port');
  final port = (portIndex != -1 && args.length > portIndex + 1)
      ? int.tryParse(args[portIndex + 1])
      : null;

  await bootstrap();
  await ServerCluster(
    port: port ?? Khadem.env.getInt("APP_PORT", defaultValue: 9000),
    instances: 12,
    globalBootstrap: () async {},
    onInit: (server) async {
      registerRoutes(server);
    },
  ).start();
}
''';

  static const _kernel = '''
import 'package:ignite_dart/src/core/http/contracts/middleware_contract.dart';

class Kernel {
  List<Middleware> get middleware => [];
}
''';

  static const _dockerfile = '''
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/server.dart -o /app/server

FROM scratch
COPY --from=build /app/server /server
COPY --from=build /app/public /public
COPY --from=build /app/storage /storage
COPY --from=build /app/.env /.env

EXPOSE 8080
CMD ["/server"]
''';
}
