<div align="center">
  <img src="assets/logo.png" alt="Khadem Framework" width="120" height="120">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/status-beta-yellow" alt="Status">
  <img src="https://img.shields.io/badge/version-1.0.2--beta-blue" alt="Version">
  <img src="https://img.shields.io/badge/dart-%3E%3D3.0.0-blue" alt="Dart">
  <img src="https://img.shields.io/badge/license-Apache--2.0-green" alt="License">
</div>

# Khadem

⚡ **A powerful, modern Dart backend framework for building scalable web applications**

Khadem is a comprehensive backend framework built with Dart, designed for developers who demand performance, elegance, and full control. It provides a complete toolkit for building robust web applications with features like dependency injection, modular architecture, built-in CLI tools with **automatic command discovery**, database management, caching, authentication, and production-ready deployment capabilities.

---

## 🚀 Key Features

### Core Architecture
- 🚀 **High Performance**: Built with Dart for exceptional speed and efficiency
- 🧱 **Modular Design**: Service provider architecture for clean, maintainable code
- 📦 **Dependency Injection**: Flexible container-based dependency management
- ⚙️ **Configuration System**: Environment-aware configuration with dot-notation support

### Development Tools
- 🛠️ **Powerful CLI**: Comprehensive command-line tools with **auto-discovery**
- 🤖 **Code Generation**: Automated generation of models, controllers, middleware, providers, jobs, and listeners
- 🔥 **Hot Reload**: Development server with hot reload support
- 📝 **Migration System**: Database migration and seeding support

### Data & Storage
- 🗄️ **Database Layer**: Support for MySQL with ORM capabilities
- 💾 **Multiple Drivers**: MySQL, Redis, and extensible driver system
- 🧵 **Queue System**: Background job processing with Redis support
- 📁 **File Storage**: Flexible file upload and storage management

### Security & Auth
- 🔐 **JWT Authentication**: Secure token-based authentication system
- 🛡️ **Middleware System**: Request/response middleware for security and processing
- ✅ **Input Validation**: Comprehensive validation rules and error handling
- 🔒 **Security Features**: Built-in protection against common web vulnerabilities

### Production Ready
- 📈 **Caching**: Multiple caching drivers (Redis, memory-based)
- ⏰ **Task Scheduling**: Background job scheduling and processing
- 📝 **Logging**: Structured logging with multiple output formats

---

## 📦 Installation

Install Khadem CLI globally for project management:

```bash
dart pub global activate khadem
```

### Requirements
- **Dart SDK**: >=3.0.0
- **Supported Platforms**: Windows, macOS, Linux
- **Database**: MySQL (optional)
- **Cache**: Redis (optional)

---

## ⚡ Quick Start

Get started with Khadem in minutes:

### 1. Create New Project Structure
```bash
# Create new project from GitHub template
khadem new --name=my_app
cd my_app
dart pub get
```
### 2. Start Development Server
```bash
# Run your Khadem application
dart run lib/main.dart

# Or for development with hot reload:
khadem serve
```

Your application will be running at `http://localhost:3000` with hot reload enabled!

---

## 📁 Project Structure

A typical Khadem project follows this modern structure:

```
my_app/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app/
│   │   ├── http/
│   │   │   ├── controllers/   # HTTP controllers
│   │   │   └── middleware/    # HTTP middleware
│   │   ├── jobs/             # Background job classes
│   │   ├── listeners/        # Event listeners
│   │   ├── models/           # Data models
│   │   └── providers/        # Service providers
│   ├── bin/                  # CLI commands and utilities
│   ├── config/
│   │   └── app.dart         # Application configuration
│   ├── core/
│   │   └── kernel.dart      # Application kernel
│   ├── database/
│   │   ├── migrations/      # Database migrations
│   │   └── seeders/         # Database seeders
│   └── routes/
│       ├── web.dart         # Web routes
│       └── socket.dart      # Socket routes
├── config/
│   ├── development/         # Development environment configs
│   │   └── logging.json
│   └── production/          # Production environment configs
│       └── logging.json
├── lang/
│   ├── ar/                  # Arabic translations
│   │   ├── ar.json
│   │   ├── fields.json
│   │   └── validation.json
│   └── en/                  # English translations
│       ├── en.json
│       ├── fields.json
│       └── validation.json
├── public/
│   └── assets/              # Public assets
│       └── logo.png
├── resources/
│   └── views/               # View templates
│       └── welcome.khdm.html
├── storage/
│   └── logs/                # Application logs
│       └── app.log
├── tests/                   # Test files
├── .env                     # Environment variables
├── .gitignore              # Git ignore rules
├── pubspec.yaml            # Package configuration
└── pubspec.lock            # Package lock file
```

---

## 🛠️ CLI Commands

Khadem features a powerful CLI with **automatic command discovery**:

### 🎯 Available Commands

### Project Management
```bash
# Create new project with modern structure
khadem new --name=project_name

# Start development server with hot reload
khadem serve

# Build Docker containers and production assets
khadem build --services=mysql,redis
```

### Code Generation
```bash
# Create models, controllers, and more in the proper lib/app/ structure
khadem make:model --name=User                    # → lib/app/models/
khadem make:controller --name=UserController     # → lib/app/http/controllers/
khadem make:middleware --name=AuthMiddleware     # → lib/app/http/middleware/
khadem make:provider --name=AuthServiceProvider # → lib/app/providers/
khadem make:job --name=SendEmailJob              # → lib/app/jobs/
khadem make:listener --name=UserEventListener   # → lib/app/listeners/
khadem make:migration --name=users               # → lib/database/migrations/

# Support for nested folders
khadem make:controller --name=api/v1/UserController  # → lib/app/http/controllers/api/v1/
khadem make:job --name=email/SendWelcomeEmailJob     # → lib/app/jobs/email/
```



### Version Information
```bash
khadem --version                  # Show version information
```

The version command reads information dynamically from `pubspec.yaml`, ensuring version information is always up-to-date and synchronized with your package configuration.

---

## 💡 Core Concepts

### Service Providers
Organize your application logic with service providers:

```dart
// lib/app/providers/app_service_provider.dart
class AppServiceProvider extends ServiceProvider {
  @override
  void register(container) {
    // Register services in the container
  }

  @override
  Future<void> boot(container) async {
    // Boot services after registration
  }
}
```

### Background Jobs
Create background jobs for asynchronous processing:

```dart
// lib/app/jobs/send_email_job.dart
class SendEmailJob extends QueueJob {
  final String email;
  final String message;

  SendEmailJob(this.email, this.message);

  @override
  Future<void> handle() async {
    // Send email logic here
    print('📧 Sending email to $email: $message');
  }
}
```

### Dependency Injection
Use the container for clean dependency management:

```dart
// lib/app/http/controllers/user_controller.dart
class UserController {
  final UserRepository repository;

  UserController(this.repository);

  Future<Response> index(Request request) async {
    final users = await repository.all();
    return Response.json(users);
  }
}
```

### Middleware System
Add cross-cutting concerns with middleware:

```dart
// lib/app/http/middleware/auth_middleware.dart
class AuthMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
    // Check authentication logic here (e.g., verify JWT token)
    await next();
  };

  @override
  String get name => 'Auth';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
```

### Database Migrations
Manage database schema with migrations:

```dart
// lib/database/migrations/123456_create_users_table.dart
class CreateUsersTable extends MigrationFile {
  @override
  Future<void> up(builder) async {
    builder.create('users', (table) {
      table.id();
      table.string('name');
      table.string('email').unique();
      table.string('password');
      table.timestamps();
    });
  }

  @override
  Future<void> down(builder) async {
    builder.dropIfExists('users');
  }
}
```

---

## 🌟 Why Choose Khadem?

- **⚡ Performance First**: Built with Dart for exceptional speed and efficiency
- **🎯 Developer Experience**: Intuitive API design with excellent tooling and auto-discovery
- **🏗️ Modern Structure**: Follows Dart package conventions with `lib/` directory organization
- **🔧 Full Control**: No magic - complete transparency and control over your application
- **📈 Scalable**: Designed to handle growth from prototype to production scale
- **🔒 Secure**: Security best practices built-in from the ground up
- **🌍 Growing Ecosystem**: Active development with expanding feature set
- **🤖 Smart CLI**: Powerful command-line tools with automatic discovery and nested folder support
- **🔥 Modern**: Takes advantage of latest Dart features and best practices
- **📊 Dynamic Configuration**: Version and metadata automatically synchronized
- **🐳 Production Ready**: Docker support with optimized containers for deployment

---

## � License

Khadem is licensed under the [Apache License 2.0](LICENSE.md). This permissive license allows you to use, modify, and distribute the framework freely, including for commercial purposes, as long as you include the original copyright notice and license text.

For more details, see the [LICENSE.md](LICENSE.md) file in this repository.

---

## �📞 Support & Community

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/khedrmahmoud/khadem/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/khedrmahmoud/khadem/discussions)
- 💬 **Community**: Join our growing community of Dart backend developers

### Getting Help
1. **Check the README** - Most common questions are answered here
2. **Browse [existing issues](https://github.com/khedrmahmoud/khadem/issues)** - Your question might already be answered
3. **Create a new issue** - For bugs, include code examples and error messages
4. **Start a discussion** - For feature requests and general questions

---

**Built with ❤️ for the Dart community by [Khedr Mahmoud](https://github.com/khedrmahmoud)**

> *"Empowering developers to build powerful backend applications with the elegance and performance of Dart"*

---