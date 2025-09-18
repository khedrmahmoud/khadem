import 'dart:async';
import 'dart:io';
import 'package:khadem/khadem_dart.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

class ServerLifecycle {
  final ServerRouter _router;
  final ServerMiddleware _middleware;
  final ServerStatic _static;
  void Function()? _initializer;
  vm.VmService? _vmService;
  vm.IsolateRef? _isolate;

  ServerLifecycle(this._router, this._middleware, this._static);

  void setInitializer(void Function() initializer) {
    _initializer = initializer;
  }

  // Connect to VM service
  Future<void> connectToVmService([String? vmServiceUri]) async {
    vmServiceUri ??= Khadem.env.get(  'VM_SERVICE_URI' );
    if (vmServiceUri == null) {
      Khadem.logger.info('No VM service URI provided, skipping hot reload setup');
      return;
    }
    
    try {
      _vmService = await vmServiceConnectUri(vmServiceUri);
      final vmObj = await _vmService!.getVM();
      _isolate = vmObj.isolates?.first;
      Khadem.logger
          .info('Connected to VM service and isolate ${_isolate?.name}');
    } catch (e) {
      Khadem.logger.error('Failed to connect to VM service: $e');
    }
  }

  Future<void> reload() async {
    // Try VM service reload first
    if (_vmService != null && _isolate != null) {
      try {
        await _vmService!.reloadSources(_isolate!.id!);
        Khadem.logger.info('🔄 Hot reload successful!');
        return;
      } catch (e) {
        Khadem.logger.error(
            'VM service reload failed, falling back to manual reload: $e',);
      }
    }

    // Fallback to manual reload
    if (_initializer != null) {
      _router.clear();
      _middleware.clear();
      _static.clear();
      _initializer!();
    }
  }

  Future<void> restart() async {
    if (_vmService != null && _isolate != null) {
      try {
        // Use the service extension for hot restart
        await _vmService!.callServiceExtension(
          'ext.dart.io.restart',
          args: {'isolateId': _isolate!.id!},
        );
        Khadem.logger.info('🔄 Hot restart successful!');
        return;
      } catch (e) {
        Khadem.logger.error('VM service restart failed: $e');
      }
    }

    Khadem.logger
        .error('Full restart required - please restart the server manually');
  }

  Future<void> start({int port = 8080}) async {
    // Note: VM service connection is handled externally by the serve command
    // We don't connect to VM service from within the server process itself

    final handler = HttpRequestProcessor(
      router: _router.router,
      globalMiddleware: _middleware.pipeline,
      staticHandler: _static.staticHandler,
    );

    final server =
        await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    Khadem.logger.info('🟢 HTTP Server started on http://localhost:$port');

    await for (final raw in server) {
      final req = Request(raw);
      final res = Response(raw);

      Zone.current.fork(
        zoneValues: {
          RequestContext.zoneKey: req,
          ResponseContext.zoneKey: res,
          ServerContext.zoneKey: ServerContext(
            request: req,
            response: res,
            match: _router.router.match,
          ),
        },
      ).run(() async {
        try {
          await _middleware.pipeline.process(req, res);
          if (!res.sent) await handler.handle(req, res);
        } catch (e, stackTrace) {
          ExceptionHandler.handle(res, e, stackTrace);
        }
      });
    }
  }
}
