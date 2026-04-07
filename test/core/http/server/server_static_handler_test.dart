import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/core/http/response/response.dart';
import 'package:khadem/src/core/http/server/core/static_handler.dart';
import 'package:test/test.dart';

void main() {
  group('ServerStaticHandler Security', () {
    late Directory tempDir;
    late Directory publicDir;
    HttpServer? server;
    late HttpClient client;

    Future<void> startServer(ServerStaticHandler handler) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((rawReq) async {
        final req = Request(rawReq);
        final res = Response(rawReq);

        final served = await handler.tryServe(req, res);
        if (!served) {
          rawReq.response.statusCode = HttpStatus.notFound;
          await rawReq.response.close();
        }
      });
    }

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('khadem_static_');
      publicDir = Directory('${tempDir.path}/public');
      await publicDir.create(recursive: true);
      await File('${publicDir.path}/index.html').writeAsString('INDEX_OK');
      await File('${tempDir.path}/secret.txt').writeAsString('SECRET_DATA');
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      if (await serverAddressExists(server)) {
        await server!.close(force: true);
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('serves files inside the static directory', () async {
      await startServer(ServerStaticHandler(publicDir.path));

      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server!.port}/'),
      );
      final res = await req.close();
      final body = await utf8.decoder.bind(res).join();

      expect(res.statusCode, equals(HttpStatus.ok));
      expect(body, equals('INDEX_OK'));
    });

    test('blocks traversal attempts outside static directory', () async {
      await startServer(ServerStaticHandler(publicDir.path));

      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server!.port}/%2e%2e/secret.txt'),
      );
      final res = await req.close();
      final body = await utf8.decoder.bind(res).join();

      expect(res.statusCode, equals(HttpStatus.notFound));
      expect(body.contains('SECRET_DATA'), isFalse);
    });
  });
}

Future<bool> serverAddressExists(HttpServer? server) async {
  if (server == null) return false;
  try {
    return server.port > 0;
  } catch (_) {
    return false;
  }
}
