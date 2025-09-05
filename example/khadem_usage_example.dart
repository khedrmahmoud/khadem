import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/core/routing/router.dart';

/// Example configuration for Khadem services
class KhademExample {
  static void configure() {
    // Load configuration
    Khadem.loadConfigs({
      'app': {
        'url': 'http://localhost:8080',
        'asset_url': 'http://localhost:8080',
        'force_https': false,
      },
      'storage': {
        'default': 'local',
        'disks': {
          'local': {
            'driver': 'local',
            'root': './storage/app',
          },
          'public': {
            'driver': 'local',
            'root': './storage/app/public',
          },
        },
      },
      'routes': {
        'home': '/',
        'user.profile': '/user/:id',
        'post.show': '/posts/:id',
        'admin.dashboard': '/admin/dashboard',
      },
    });
  }

  static Future<void> bootstrap() async {
    // Register core services (only essential framework services)
    await Khadem.registerCoreServices();

    // Register application services (user-managed, like Laravel's Kernel)
    await Khadem.registerApplicationServices([
      // Add your application service providers here
      // Example: QueueServiceProvider(), AuthServiceProvider(), etc.
    ]);

    // Boot all services
    await Khadem.boot();
  }

  static void demonstrateFormDirectives() {
    print('\n=== Form Directives Demo ===');

    // Example HTML template with form directives
    const template = '''
<!DOCTYPE html>
<html>
<head>
    <title>Form Example</title>
</head>
<body>
    <h1>Contact Form</h1>

    <!-- CSRF Protection -->
    <form method="POST" action="@action('ContactController@store')">
        @csrf

        <!-- Method Spoofing for PUT/PATCH/DELETE -->
        @method('POST')

        <div>
            <label>Name:</label>
            <input type="text" name="name" required>
        </div>

        <div>
            <label>Email:</label>
            <input type="email" name="email" required>
        </div>

        <button type="submit">Submit</button>
    </form>

    <!-- Navigation Links -->
    <nav>
        <a href="@url('/home')">Home</a>
        <a href="@route('user.profile', id: 123)">My Profile</a>
        <a href="@route('posts.index')">All Posts</a>
    </nav>

    <!-- Asset Links -->
    <link rel="stylesheet" href="@css('forms.css')">
    <script src="@js('validation.js')"></script>
</body>
</html>
''';

    print('Template with form directives:');
    print(template);
    print('\nAfter processing, these would become:');
    print('- @csrf → <input type="hidden" name="_token" value="csrf_123456789_123">');
    print('- @method(\'POST\') → <input type="hidden" name="_method" value="POST">');
    print('- @action(\'ContactController@store\') → /contact/store');
    print('- @url(\'/home\') → http://localhost:8080/home');
    print('- @route(\'user.profile\', id: 123) → http://localhost:8080/user/123');
    print('- @css(\'forms.css\') → http://localhost:8080/assets/css/forms.css');
  }

  static Future<void> demonstrateFileStorage() async {
    // Store a text file
    final textUrl = await Khadem.storeTextFile(
      'example.txt',
      'Hello, Khadem!',
    );
    print('Stored text file at: $textUrl');

    // Store binary data
    final imageData = [72, 101, 108, 108, 111]; // Example binary data
    final imageUrl = await Khadem.storeFile(
      'example.png',
      imageData,
    );
    print('Stored image at: $imageUrl');

    // Check if file exists
    final exists = await Khadem.assetService.fileExists('example.txt');
    print('File exists: $exists');

    // Get file size
    if (exists) {
      final size = await Khadem.assetService.fileSize('example.txt');
      print('File size: $size bytes');
    }
  }
}

/// Example of how to bootstrap Khadem with clean separation of concerns
class KhademBootstrapExample {
  static Future<void> bootstrap() async {
    // Step 1: Configure the framework
    KhademExample.configure();

    // Step 2: Register only core services (framework essentials)
    await Khadem.registerCoreServices();

    // Step 3: Register your application services (user-managed)
    // This is similar to Laravel's Kernel where you control your providers
    await Khadem.registerApplicationServices([
      // Add your application service providers here
      // Example: QueueServiceProvider(), AuthServiceProvider(), etc.
    ]);

    // Step 4: Boot all services
    await Khadem.boot();

    // Now you can use all Khadem features!
    demonstrateUrlGeneration();
    await demonstrateFileStorage();
  }

  static void demonstrateUrlGeneration() {
    print('\n=== URL Generation Demo ===');

    // Generate URLs using Laravel-style helpers
    final homeUrl = Khadem.url('/');
    final profileUrl = Khadem.route('user.profile', parameters: {'id': '123'});
    final assetUrl = Khadem.asset('images/logo.png');
    final cssUrl = Khadem.css('app.css');

    print('Home URL: $homeUrl');
    print('Profile URL: $profileUrl');
    print('Asset URL: $assetUrl');
    print('CSS URL: $cssUrl');
  }

  static void setupRoutes() {
    final router = Khadem.container.resolve<Router>();

    // Register routes with names
    router.get('/', (request, response) {
      // Handle home route
      print('Home route accessed');
    }, name: 'home');

    router.get('/user/:id', (request, response) {
      // Handle user profile route
      print('User profile route accessed');
    }, name: 'user.profile');

    router.get('/posts/:id', (request, response) {
      // Handle post show route
      print('Post show route accessed');
    }, name: 'post.show');

    router.get('/admin/dashboard', (request, response) {
      // Handle admin dashboard route
      print('Admin dashboard route accessed');
    }, name: 'admin.dashboard');
  }

  static void demonstrateFormDirectives() {
    print('\n=== Form Directives Demo ===');

    // Example HTML template with form directives
    const template = '''
<!DOCTYPE html>
<html>
<head>
    <title>Form Example</title>
</head>
<body>
    <h1>Contact Form</h1>

    <!-- CSRF Protection -->
    <form method="POST" action="@action('ContactController@store')">
        @csrf

        <!-- Method Spoofing for PUT/PATCH/DELETE -->
        @method('POST')

        <div>
            <label>Name:</label>
            <input type="text" name="name" required>
        </div>

        <div>
            <label>Email:</label>
            <input type="email" name="email" required>
        </div>

        <button type="submit">Submit</button>
    </form>

    <!-- Navigation Links -->
    <nav>
        <a href="@url('/home')">Home</a>
        <a href="@route('user.profile', id: 123)">My Profile</a>
        <a href="@route('posts.index')">All Posts</a>
    </nav>

    <!-- Asset Links -->
    <link rel="stylesheet" href="@css('forms.css')">
    <script src="@js('validation.js')"></script>
</body>
</html>
''';

    print('Template with form directives:');
    print(template);
    print('\nAfter processing, these would become:');
    print('- @csrf → <input type="hidden" name="_token" value="csrf_123456789_123">');
    print('- @method(\'POST\') → <input type="hidden" name="_method" value="POST">');
    print('- @action(\'ContactController@store\') → /contact/store');
    print('- @url(\'/home\') → http://localhost:8080/home');
    print('- @route(\'user.profile\', id: 123) → http://localhost:8080/user/123');
    print('- @css(\'forms.css\') → http://localhost:8080/assets/css/forms.css');
  }

  static Future<void> demonstrateFileStorage() async {
    // Store a text file
    final textUrl = await Khadem.storeTextFile(
      'example.txt',
      'Hello, Khadem!',
    );
    print('Stored text file at: $textUrl');

    // Store binary data
    final imageData = [72, 101, 108, 108, 111]; // Example binary data
    final imageUrl = await Khadem.storeFile(
      'example.png',
      imageData,
    );
    print('Stored image at: $imageUrl');

    // Check if file exists
    final exists = await Khadem.assetService.fileExists('example.txt');
    print('File exists: $exists');

    // Get file size
    if (exists) {
      final size = await Khadem.assetService.fileSize('example.txt');
      print('File size: $size bytes');
    }
  }
}
