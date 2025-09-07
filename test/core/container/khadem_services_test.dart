import 'package:test/test.dart';
import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/support/services/url_service.dart';
import 'package:khadem/src/core/container/container_provider.dart';
import 'package:khadem/src/core/storage/storage_manager.dart';

void main() {
  group('Khadem URL & Asset Services Integration', () {
    setUp(() async {
      // Create a simple container for testing
      final container = ContainerProvider.instance;

      // Register services directly
      final urlService = UrlService(
        baseUrl: 'http://localhost:8080',
        assetBaseUrl: 'http://localhost:8080',
      );

      // Register routes
      urlService.registerRoute('home', '/');
      urlService.registerRoute('user.profile', '/user/:id');
      urlService.registerRoute('post.show', '/posts/:id');

      final storageManager = StorageManager();
      final assetService = AssetService(urlService, storageManager);

      container.instance<UrlService>(urlService);
      container.instance<StorageManager>(storageManager);
      container.instance<AssetService>(assetService);

      // Use the test container
      await Khadem.use(container);
    });

    test('should resolve UrlService from container', () {
      final urlService = Khadem.urlService;
      expect(urlService, isNotNull);
      expect(urlService, isA<UrlService>());
    });

    test('should generate URLs using Khadem.url helper', () {
      final url = Khadem.url('/test');
      expect(url, equals('http://localhost:8080/test'));
    });

    test('should generate route URLs using Khadem.route helper', () {
      final routeUrl = Khadem.route('user.profile', parameters: {'id': '123'});
      expect(routeUrl, equals('http://localhost:8080/user/123'));
    });

    test('should generate asset URLs using Khadem.asset helper', () {
      final assetUrl = Khadem.asset('images/logo.png');
      expect(assetUrl, equals('http://localhost:8080/assets/images/logo.png'));
    });

    test('should generate CSS asset URLs using Khadem.css helper', () {
      final cssUrl = Khadem.css('app.css');
      expect(cssUrl, equals('http://localhost:8080/assets/css/app.css'));
    });

    test('should generate JS asset URLs using Khadem.js helper', () {
      final jsUrl = Khadem.js('app.js');
      expect(jsUrl, equals('http://localhost:8080/assets/js/app.js'));
    });

    test('should generate image asset URLs using Khadem.image helper', () {
      final imageUrl = Khadem.image('logo.png');
      expect(imageUrl, equals('http://localhost:8080/assets/images/logo.png'));
    });
  });
}
