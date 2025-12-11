import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:khadem/khadem.dart';
import 'package:khadem/src/core/http/server/server.dart';
import 'package:khadem/src/contracts/env/env_interface.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:test/test.dart';

class FakeEnv implements EnvInterface {
  @override
  String? get(String key) => null;

  @override
  String getOrDefault(String key, String defaultValue) => defaultValue;

  @override
  String getOrFail(String key) => throw Exception('Env key $key not found');

  @override
  bool getBool(String key, {bool defaultValue = false}) => defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) => defaultValue;

  @override
  double getDouble(String key, {double defaultValue = 0.0}) => defaultValue;

  @override
  List<String> getList(String key, {String separator = ',', List<String> defaultValue = const []}) => defaultValue;

  @override
  void set(String key, String value) {}

  @override
  bool has(String key) => false;

  @override
  Map<String, String> all() => {};

  @override
  List<String> get loadedFiles => [];

  @override
  void loadFromFile(String path) {}

  @override
  void clear() {}

  @override
  List<String> validateRequired(List<String> requiredKeys) => [];
}

void main() {
  group('Server Middleware Groups', () {
    late Server server;
    final int port = 8081;

    setUp(() {
      // Register mocks
      final container = ContainerProvider.instance;
      container.instance<EnvInterface>(FakeEnv());
      container.instance<Logger>(Logger());
      
      server = Server();
    });

    tearDown(() async {
      await server.stop();
      ContainerProvider.instance.flush();
    });

    test('middleware group is applied and persists after reload', () async {
      bool groupMiddlewareExecuted = false;

      // Define a group
      server.middlewareGroup('api', [
        Middleware((req, res, next) async {
          groupMiddlewareExecuted = true;
          res.headers.setHeader('X-Group-Middleware', 'executed');
          await next();
        }),
      ]);

      // Use the group
      server.useMiddlewareGroup('api');

      // Add a route
      server.injectRoutes((router) {
        router.get('/test', (req, res) {
          res.send('OK');
        });
      });

      // Start server in background
      unawaited(server.start(port: port));
      
      // Wait for server to start
      await Future.delayed(Duration(milliseconds: 500));

      try {
        // Request 1
        var response = await http.get(Uri.parse('http://localhost:$port/test'));
        expect(response.statusCode, 200);
        expect(response.headers['x-group-middleware'], 'executed');
        expect(groupMiddlewareExecuted, isTrue);

        // Reset flag
        groupMiddlewareExecuted = false;

        // Reload server
        await server.reload();

        // Request 2 (after reload)
        response = await http.get(Uri.parse('http://localhost:$port/test'));
        expect(response.statusCode, 200);
        expect(response.headers['x-group-middleware'], 'executed');
        expect(groupMiddlewareExecuted, isTrue);
      } finally {
        await server.stop();
      }
    });

    test('getMiddlewareGroup returns the correct middlewares', () {
      final middleware = Middleware((req, res, next) async {});
      server.middlewareGroup('test', [middleware]);
      
      final group = server.getMiddlewareGroup('test');
      expect(group, hasLength(1));
      expect(group.first, equals(middleware));
    });
  });
}
