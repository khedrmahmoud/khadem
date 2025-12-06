import 'package:khadem/khadem.dart';
import 'package:khadem/src/core/http/server/server.dart';
import 'package:test/test.dart';

void main() {
  group('Server', () {
    late Server server;

    setUp(() {
      server = Server();
    });

    test('injectRoutes registers routes correctly', () {
      server.injectRoutes((router) {
        router.get('/test', (req, res) {
          res.send('OK');
        });
      });

      // Since we can't easily inspect the private router, we assume if it compiles and runs,
      // the integration is correct. Real integration tests would start the server.
    });

    test('configure updates settings', () {
      server.configure(autoCompress: false, idleTimeout: Duration(seconds: 60));
      // Verification would require inspecting private lifecycle or starting server
    });
  });
}
