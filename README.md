<div align="center">
  <img src="assets/logo.png" alt="Khadem Framework" width="120" height="120">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/status-beta-yellow" alt="Status">
  <img src="https://img.shields.io/badge/version-1.0.0--beta-blue" alt="Version">
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
# Install from local source (for development)
dart pub global activate --source path /path/to/khadem
```

### Requirements
- **Dart SDK**: >=3.0.0
- **Supported Platforms**: Windows, macOS, Linux
- **Database**: MySQL (optional)
- **Cache**: Redis (optional)

### Core Dependencies
Khadem uses these key dependencies for optimal performance:

- **args**: Command-line argument parsing for CLI tools
- **mysql1**: MySQL database connectivity
- **redis**: Redis caching and queue support
- **dart_jsonwebtoken**: JWT authentication
- **dotenv**: Environment variable management
- **watcher**: File watching for hot reload
- **yaml**: YAML configuration parsing

---

## ⚡ Quick Start

Get started with Khadem in minutes:

### 1. Create New Project Structure
```bash
khadem new --name=my_app
cd my_app
dart pub get
```

### 2. Start Development Server
```bash
# Run your Khadem application
dart run bin/server.dart

# Or use CLI for hot reload:
# khadem serve
```

Your application will be running at `http://localhost:3000` with hot reload enabled!

---

## 📁 Project Structure

A typical Khadem project follows this structure:

```
my_app/
├── app/
│   ├── http/
│   │   ├── controllers/     # HTTP controllers
│   │   └── middleware/      # HTTP middleware
│   ├── jobs/               # Background job classes
│   ├── listeners/          # Event listeners
│   ├── models/             # Data models
│   └── providers/          # Service providers
├── bin/
│   └── server.dart         # Application entry point
├── config/
│   ├── app.dart           # Application configuration
│   └── development/       # Environment-specific configs
├── core/
│   └── kernel.dart        # Application kernel
├── database/
│   ├── migrations/        # Database migrations
│   └── seeders/          # Database seeders
├── lang/
│   ├── ar/               # Arabic translations
│   └── en/               # English translations
├── public/
│   └── index.html        # Static files
├── resources/
│   └── views/            # View templates
├── routes/
│   ├── web.dart          # Web routes
│   └── socket.dart       # Socket routes
├── storage/              # File storage
├── tests/                # Test files
├── .env                  # Environment variables
└── pubspec.yaml
```

---

## 🛠️ CLI Commands

Khadem features a powerful CLI with **automatic command discovery**:

### 🎯 Available Commands

### Project Management
```bash
# Create new project
khadem new --name=project_name

# Start development server with hot reload
khadem serve

# Build for production
khadem build
```

### Code Generation
```bash
khadem make:model --name=User
khadem make:controller --name=UserController
khadem make:middleware --name=AuthMiddleware
khadem make:provider --name=AuthServiceProvider
khadem make:job --name=SendEmailJob
khadem make:listener --name=UserEventListener
khadem make:migration --name=create_users_table
```

### Version Information
```bash
khadem --version                  # Show version information
khadem version --verbose          # Show detailed version info
```

The version command reads information dynamically from `pubspec.yaml`, ensuring version information is always up-to-date and synchronized with your package configuration.

---

## 💡 Core Concepts

### Service Providers
Organize your application logic with service providers:

```dart
class AppServiceProvider extends ServiceProvider {
  @override
  void register(container) {}

  @override
  Future<void> boot(container) async {}
}
```

### Dependency Injection
Use the container for clean dependency management:

```dart
class UserController {
  final UserRepository repository;

  UserController(this.repository);

  // Constructor injection
}
```

### Middleware System
Add cross-cutting concerns with middleware:

```dart
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

---

## 🌟 Why Choose Khadem?

- **⚡ Performance First**: Built with Dart for exceptional speed and efficiency
- **🎯 Developer Experience**: Intuitive API design with excellent tooling and auto-discovery
- **🔧 Full Control**: No magic - complete transparency and control over your application
- **📈 Scalable**: Designed to handle growth from prototype to production scale
- **🔒 Secure**: Security best practices built-in from the ground up
- **🌍 Growing Ecosystem**: Active development with expanding feature set
- **🤖 Smart CLI**: Powerful command-line tools with automatic discovery
- **🔥 Modern**: Takes advantage of latest Dart features and best practices
- **📊 Dynamic Configuration**: Version and metadata automatically synchronized

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