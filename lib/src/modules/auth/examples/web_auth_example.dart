import 'package:khadem/khadem_dart.dart';
import '../middlewares/web_auth_middleware.dart';

/// Example usage of Web Authentication Middleware
///
/// This file demonstrates how to use the various web authentication
/// middlewares in your Khadem application.
class AuthRoutes {
  /// Register authentication routes with middleware
  static void register(Router router) {
    // Public routes (no auth required)
    router.get('/login', _loginPage, middleware: [WebAuthMiddleware.guest()]);
    router.get('/register', _registerPage, middleware: [WebAuthMiddleware.guest()]);
    router.post('/login', _login, middleware: [WebAuthMiddleware.guest()]);
    router.post('/register', _register, middleware: [WebAuthMiddleware.guest()]);

    // Protected routes (auth required)
    router.get('/dashboard', _dashboard, middleware: [WebAuthMiddleware.auth()]);
    router.get('/profile', _profile, middleware: [WebAuthMiddleware.auth()]);
    router.post('/profile/update', _updateProfile, middleware: [WebAuthMiddleware.auth()]);

    // Admin-only routes
    router.get('/admin', _adminDashboard, middleware: [WebAuthMiddleware.admin()]);
    router.get('/admin/users', _adminUsers, middleware: [WebAuthMiddleware.admin()]);

    // Role-based routes
    router.get('/moderator', _moderatorPanel,
        middleware: [WebAuthMiddleware.roles(['moderator', 'admin'])]);
    router.get('/editor', _editorPanel,
        middleware: [WebAuthMiddleware.roles(['editor', 'admin'])]);

    // Permission-based routes
    router.post('/posts', _createPost,
        middleware: [WebAuthMiddleware.permissions(['create_posts'])]);
    router.delete('/posts/:id', _deletePost,
        middleware: [WebAuthMiddleware.permissions(['delete_posts'])]);

    // Routes with exceptions
    router.get('/api/public', _publicApi, middleware: [
      WebAuthMiddleware.auth(except: ['/api/public/status'])
    ]);

    // Logout route
    router.post('/logout', _logout, middleware: [WebAuthMiddleware.auth()]);
  }

  // Route handlers
  static Future<void> _loginPage(Request request, Response response) async {
    // Render login page
    response.view('auth/login', data: {
      'title': 'Login',
      ...request.webViewData, // Includes flash messages, CSRF token, etc.
    });
  }

  static Future<void> _registerPage(Request request, Response response) async {
    response.view('auth/register', data: {
      'title': 'Register',
      ...request.webViewData,
    });
  }

  static Future<void> _login(Request request, Response response) async {
    final authService = WebAuthService.create();

    try {
      final credentials = {
        'email': request.input('email'),
        'password': request.input('password'),
      };

      await authService.attemptLogin(credentials,
          remember: request.input('remember') == 'on');

      // Redirect to intended URL or dashboard
      final intendedUrl = request.session.get('url.intended') as String? ?? '/dashboard';
      request.session.remove('url.intended');

      response.redirect(intendedUrl);
    } catch (e) {
      response.redirect('/login');
    }
  }

  static Future<void> _register(Request request, Response response) async {
    // Registration logic here
    response.redirect('/login');
  }

  static Future<void> _dashboard(Request request, Response response) async {
    response.view('dashboard', data: {
      'title': 'Dashboard',
      'user': request.user,
      ...request.webViewData,
    });
  }

  static Future<void> _profile(Request request, Response response) async {
    response.view('profile', data: {
      'title': 'Profile',
      'user': request.user,
      ...request.webViewData,
    });
  }

  static Future<void> _updateProfile(Request request, Response response) async {
    // Update profile logic
    response.redirect('/profile');
  }

  static Future<void> _adminDashboard(Request request, Response response) async {
    response.view('admin/dashboard', data: {
      'title': 'Admin Dashboard',
      'user': request.user,
      ...request.webViewData,
    });
  }

  static Future<void> _adminUsers(Request request, Response response) async {
    response.view('admin/users', data: {
      'title': 'User Management',
      'user': request.user,
      ...request.webViewData,
    });
  }

  static Future<void> _moderatorPanel(Request request, Response response) async {
    response.view('moderator/panel', data: {
      'title': 'Moderator Panel',
      'user': request.user,
      ...request.webViewData,
    });
  }

  static Future<void> _editorPanel(Request request, Response response) async {
    response.view('editor/panel', data: {
      'title': 'Editor Panel',
      'user': request.user,
      ...request.webViewData,
    });
  }

  static Future<void> _createPost(Request request, Response response) async {
    // Create post logic
    response.sendJson({'message': 'Post created successfully'});
  }

  static Future<void> _deletePost(Request request, Response response) async {
    // Delete post logic
    response.sendJson({'message': 'Post deleted successfully'});
  }

  static Future<void> _publicApi(Request request, Response response) async {
    response.sendJson({'message': 'Public API endpoint'});
  }

  static Future<void> _logout(Request request, Response response) async {
    final authService = WebAuthService.create();
    await authService.logout(request, response);

    response.redirect('/login');
  }
}

/// Advanced middleware configuration examples
class AdvancedAuthSetup {
  static void configureAdvancedAuth(Router router) {
    // Custom middleware with specific guard
    final customAuth = WebAuthMiddleware.create(
      redirectTo: '/auth/login',
      except: ['/api/health', '/api/status'],
      regenerateSession: true,
      guard: 'web',
    );

    // Role middleware requiring ALL specified roles
    final strictRoleAuth = WebAuthMiddleware.roles(
      ['editor', 'publisher'],
      requireAll: true,
      redirectTo: '/unauthorized',
    );

    // Permission middleware requiring ANY of the permissions
    final flexiblePermissionAuth = WebAuthMiddleware.permissions(
      ['read_content', 'write_content', 'admin_content'],
      requireAll: false,
    );

    // Apply to routes
    router.get('/content/manage', _manageContent,
        middleware: [customAuth, strictRoleAuth]);
    router.post('/content/publish', _publishContent,
        middleware: [customAuth, flexiblePermissionAuth]);
  }

  static Future<void> _manageContent(Request request, Response response) async {
    response.view('content/manage', data: request.webViewData);
  }

  static Future<void> _publishContent(Request request, Response response) async {
    response.sendJson({'published': true});
  }
}
