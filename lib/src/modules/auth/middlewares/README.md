# Web Authentication Middleware

Powerful middleware for protecting web routes with session-based authentication in Khadem.

## Features

- ✅ **Session-based authentication** with automatic validation
- ✅ **Brute force protection** with configurable lockout
- ✅ **Role-based access control** (RBAC)
- ✅ **Permission-based access control**
- ✅ **Guest middleware** for login/register pages
- ✅ **Flash messages** for user feedback
- ✅ **CSRF protection** integration
- ✅ **Session regeneration** for security
- ✅ **Intended URL redirect** after login

## Quick Start

```dart
import 'package:khadem/khadem_dart.dart';
import 'middlewares/web_auth_middleware.dart';

void setupRoutes(Router router) {
  // Public routes
  router.get('/login', loginPage, middleware: [WebAuthMiddleware.guest()]);
  router.post('/login', login, middleware: [WebAuthMiddleware.guest()]);

  // Protected routes
  router.get('/dashboard', dashboard, middleware: [WebAuthMiddleware.auth()]);
  router.get('/profile', profile, middleware: [WebAuthMiddleware.auth()]);

  // Admin routes
  router.get('/admin', adminPanel, middleware: [WebAuthMiddleware.admin()]);

  // Role-based routes
  router.get('/editor', editorPanel,
      middleware: [WebAuthMiddleware.roles(['editor', 'admin'])]);

  // Permission-based routes
  router.post('/posts', createPost,
      middleware: [WebAuthMiddleware.permissions(['create_posts'])]);
}
```

## Available Middleware Types

### 1. Basic Authentication
```dart
WebAuthMiddleware.auth(
  redirectTo: '/login',           // Custom redirect URL
  except: ['/api/health'],        // Routes to exclude
)
```

### 2. Guest Only (for login/register pages)
```dart
WebAuthMiddleware.guest(
  redirectTo: '/dashboard',       // Where to redirect authenticated users
  except: ['/home'],             // Routes to exclude
)
```

### 3. Admin Only
```dart
WebAuthMiddleware.admin(
  redirectTo: '/login',          // Redirect for non-admins
  except: ['/api/status'],       // Routes to exclude
)
```

### 4. Role-Based
```dart
WebAuthMiddleware.roles(
  ['editor', 'moderator'],       // Required roles
  requireAll: false,             // true = ALL roles, false = ANY role
  redirectTo: '/unauthorized',
  except: ['/public'],
)
```

### 5. Permission-Based
```dart
WebAuthMiddleware.permissions(
  ['read_content', 'write_content'], // Required permissions
  requireAll: true,               // true = ALL permissions, false = ANY
  redirectTo: '/forbidden',
  except: ['/api/public'],
)
```

## Advanced Configuration

### Custom Middleware
```dart
final customAuth = WebAuthMiddleware.create(
  redirectTo: '/auth/login',
  except: ['/api/health', '/api/status'],
  regenerateSession: true,
  guard: 'web',                  // Specific auth guard
);

// Use in routes
router.get('/protected', handler, middleware: [customAuth]);
```

### Multiple Middleware
```dart
router.get('/admin/content', handler, middleware: [
  WebAuthMiddleware.auth(),
  WebAuthMiddleware.roles(['admin', 'editor'], requireAll: true),
  WebAuthMiddleware.permissions(['manage_content']),
]);
```

## Route Handlers

### Using Flash Messages
```dart
Future<void> login(Request request, Response response) async {
  final authService = WebAuthService.create();

  try {
    await authService.attemptLogin({
      'email': request.input('email'),
      'password': request.input('password'),
    });

    response.redirect('/dashboard');
  } catch (e) {
    // Flash message is automatically set by WebAuthService
    response.redirect('/login');
  }
}
```

### Rendering Views with Auth Data
```dart
Future<void> dashboard(Request request, Response response) async {
  response.view('dashboard', data: {
    'title': 'Dashboard',
    'user': request.user,
    ...request.webViewData, // Includes flash messages, CSRF token, etc.
  });
}
```

### Accessing Auth Status
```dart
Future<void> profile(Request request, Response response) async {
  final authStatus = request.webAuthStatus;

  if (authStatus['is_authenticated']) {
    // User is logged in
    final user = authStatus['user'];
    // Render profile page
  } else {
    // Redirect to login
    response.redirect('/login');
  }
}
```

## Security Features

### Brute Force Protection
- **Max attempts**: 5 failed login attempts
- **Lockout duration**: 15 minutes
- **Automatic reset**: On successful login

### Session Security
- **Automatic regeneration**: Prevents session fixation
- **Expiration handling**: Automatic logout on expired sessions
- **Secure storage**: Tokens stored in sessions, not cookies

### CSRF Protection
- **Automatic token generation**: 32-byte secure tokens
- **Session-based storage**: More secure than cookies
- **Validation helpers**: Easy token validation in forms

## Integration with WebAuthService

The middleware automatically integrates with `WebAuthService` for:
- ✅ User authentication verification
- ✅ Session validation and cleanup
- ✅ Flash message management
- ✅ CSRF token handling
- ✅ Remember token support

## Error Handling

The middleware provides user-friendly error handling:
- **Unauthenticated users**: Redirected to login with flash message
- **Insufficient privileges**: Redirected with access denied message
- **Session expired**: Automatic logout and redirect
- **Invalid tokens**: Graceful fallback with error messages

## Best Practices

1. **Use HTTPS** in production for secure cookie transmission
2. **Configure session timeouts** appropriately for your application
3. **Use role-based access** for complex permission structures
4. **Implement proper logout** to clear all session data
5. **Validate CSRF tokens** on all state-changing requests
6. **Monitor failed login attempts** for security insights

## Examples

See `web_auth_example.dart` for complete working examples of:
- Route registration with middleware
- Login/logout handlers
- Protected route handlers
- Advanced middleware configuration</content>
<parameter name="filePath">d:\Users\Khedr\src\khadem\lib\src\modules\auth\README.md
