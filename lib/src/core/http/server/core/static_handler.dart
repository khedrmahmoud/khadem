import 'dart:io';
import 'package:mime/mime.dart';
import '../../request/request.dart';
import '../../response/response.dart';

/// Responsible for serving static files from a given directory.
class ServerStaticHandler {
  final String directory;

  ServerStaticHandler(this.directory);

  /// Attempts to serve a file matching the request path.
  Future<bool> tryServe(Request req, Response res) async {
    if (req.method != 'GET') return false;

    final String safePath =
        req.path == '/' || req.path == '' ? '/index.html' : req.path;
    final String fullPath = '$directory$safePath';
    final File file = File(fullPath);

    if (!await file.exists()) return false;

    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      res.raw.response.headers.contentType = ContentType.parse(mimeType);
      await res.raw.response.addStream(file.openRead());
      await res.raw.response.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
