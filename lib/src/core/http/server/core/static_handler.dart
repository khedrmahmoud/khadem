import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import '../../request/request.dart';
import '../../response/response.dart';

/// Responsible for serving static files from a given directory.
class ServerStaticHandler {
  final String directory;
  final String _rootDirectory;

  ServerStaticHandler(this.directory)
    : _rootDirectory = p.normalize(p.absolute(directory));

  bool _isWithinStaticRoot(String resolvedPath) {
    return resolvedPath == _rootDirectory ||
        p.isWithin(_rootDirectory, resolvedPath);
  }

  /// Attempts to serve a file matching the request path.
  Future<bool> tryServe(Request req, Response res) async {
    if (req.method != 'GET') return false;

    String safePath;
    try {
      safePath = Uri.decodeComponent(req.path);
    } catch (_) {
      return false;
    }

    if (safePath == '/' || safePath.isEmpty) {
      safePath = 'index.html';
    }

    if (safePath.startsWith('/')) {
      safePath = safePath.substring(1);
    }

    final normalizedPath = p.normalize(safePath);
    if (p.isAbsolute(normalizedPath) ||
        p.split(normalizedPath).contains('..')) {
      return false;
    }

    final String fullPath = p.normalize(p.join(_rootDirectory, normalizedPath));
    if (!_isWithinStaticRoot(fullPath)) {
      return false;
    }

    final File file = File(fullPath);

    if (!await file.exists()) return false;

    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      return false;
    }

    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      res.raw.response.headers.contentType = ContentType.parse(mimeType);

      // Add caching headers for better performance
      // Cache for 1 hour by default
      res.raw.response.headers.add(
        HttpHeaders.cacheControlHeader,
        'public, max-age=3600',
      );

      // Add Last-Modified header
      final lastModified = await file.lastModified();
      res.raw.response.headers.add(
        HttpHeaders.lastModifiedHeader,
        HttpDate.format(lastModified),
      );

      // Check If-Modified-Since
      final ifModifiedSince = req.raw.headers.value(
        HttpHeaders.ifModifiedSinceHeader,
      );
      if (ifModifiedSince != null) {
        try {
          final ifModifiedDate = HttpDate.parse(ifModifiedSince);
          if (lastModified.isBefore(ifModifiedDate) ||
              lastModified.isAtSameMomentAs(ifModifiedDate)) {
            res.raw.response.statusCode = HttpStatus.notModified;
            await res.raw.response.close();
            return true;
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }

      await res.raw.response.addStream(file.openRead());
      await res.raw.response.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
