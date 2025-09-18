# Khadem

⚡ **A powerful, modern Dart backend framework for building scalable web applications**

Khadem is a comprehensive backend framework built with Dart, designed for developers who demand performance, elegance, and full control. It provides a complete toolkit for building robust web applications with features like dependency injection, modular architecture, built-in CLI tools, database management, caching, authentication, and production-ready deployment capabilities.

---

## 🚀 Key Features

### Core Architecture
- 🚀 **High Performance**: Built with Dart isolates for exceptional speed and efficiency
- 🧱 **Modular Design**: Service provider architecture for clean, maintainable code
- 📦 **Dependency Injection**: Flexible container-based dependency management
- ⚙️ **Configuration System**: Environment-aware configuration with dot-notation support

### Development Tools
- 🛠️ **Powerful CLI**: Comprehensive command-line tools for project management
- � **Code Generation**: Automated generation of models, controllers, middleware, and more
- 🔥 **Hot Reload**: Development server with instant code reloading
- 📊 **Built-in Testing**: Integrated testing framework for reliable applications

### Data & Storage
- 🗄️ **Database Layer**: Lightweight ORM with migration and seeding support
- � **Multiple Drivers**: Support for MySQL, PostgreSQL, Redis, and more
- 🧵 **Queue System**: Background job processing with multiple storage backends
- 📁 **File Storage**: Flexible file upload and storage management

### Security & Auth
- 🔐 **JWT Authentication**: Secure token-based authentication system
- 🛡️ **Middleware System**: Request/response middleware for security and processing
- ✅ **Input Validation**: Comprehensive validation rules and error handling
- � **Security Features**: Built-in protection against common web vulnerabilities

### Production Ready
- 📈 **Caching**: Multiple caching drivers (memory, Redis, file-based)
- ⏰ **Task Scheduling**: Automated task scheduling and cron job management
- 📝 **Logging**: Structured logging with multiple output formats
- 🚀 **Deployment**: Optimized build tools for production deployment

---

## ⚡ Quick Start

Get started with Khadem in minutes:

### 1. Install CLI
```bash
dart pub global activate khadem_cli
```

### 2. Create New Project
```bash
khadem new --name=my_app
cd my_app
```

### 3. Start Development Server
```bash
khadem serve
```

Your application will be running at `http://localhost:3000` with hot reload enabled!

---

## 📁 Project Structure

A typical Khadem project follows this structure:

```
my_app/
├── app/
│   ├── http/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   └── routes.dart
│   ├── models/
│   ├── providers/
│   └── jobs/
├── config/
│   ├── app.dart
│   └── database.dart
├── database/
│   ├── migrations/
│   └── seeders/
├── public/
├── storage/
├── tests/
├── bin/
│   └── server.dart
└── pubspec.yaml
```

---

## 🛠️ CLI Commands

Khadem comes with a powerful CLI for development and deployment:

### Project Management
```bash
khadem new --name=project_name    # Create new project
khadem serve                      # Start development server
khadem build                      # Build for production
```

### Code Generation
```bash
khadem make:model --name=User
khadem make:controller --name=UserController
khadem make:middleware --name=AuthMiddleware
khadem make:job --name=SendEmailJob
```

### Database Operations
```bash
khadem make:migration --name=create_users_table
# Database commands coming soon
```

---

## 💡 Core Concepts

### Service Providers
Organize your application logic with service providers:

```dart
class AuthServiceProvider extends ServiceProvider {
  @override
  Future<void> register() async {
    // Register services in the container
  }

  @override
  Future<void> boot() async {
    // Bootstrap services after registration
  }
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
class AuthMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    // Authentication logic
    return await next(request);
  }
}
```

---

## 🔧 Configuration

Khadem uses environment-based configuration:

```dart
// config/app.dart
class AppConfig {
  final String name;
  final String env;
  final bool debug;

  AppConfig({
    required this.name,
    required this.env,
    required this.debug,
  });
}
```

Access configuration anywhere in your app:

```dart
final config = Khadem.config<AppConfig>();
```

---

## 🧪 Testing

Built-in testing support for reliable applications:

```dart
import 'package:test/test.dart';
import 'package:khadem/khadem.dart';

void main() {
  test('User creation', () async {
    // Test your application logic
  });
}
```

Run tests with:
```bash
dart test
```

---

## � Deployment

Deploy your Khadem application with ease:

### Build for Production
```bash
khadem build --archive
```

### Docker Support
```bash
# Build Docker image
docker build -t my-khadem-app .

# Run container
docker run -p 3000:3000 my-khadem-app
```

---

## 📚 Documentation

- 📖 [Getting Started Guide](https://khadem.dev/docs/getting-started)
- 🏗️ [Architecture Overview](https://khadem.dev/docs/architecture)
- 🔧 [CLI Reference](https://khadem.dev/docs/cli)
- 📦 [API Reference](https://khadem.dev/api)

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

Please read our [Contributing Guide](./CONTRIBUTING.md) for detailed instructions.

---

## 📜 License

Khadem is released under a **custom MIT-based license**.

✅ **You may:**
- Use Khadem freely in your own projects
- Modify and distribute your own applications built with Khadem

🚫 **You may not:**
- Create a new backend framework from Khadem
- Use Khadem's name or branding for competing frameworks

See [LICENSE](./LICENSE.md) for complete details.

---

## 🌟 Why Khadem?

- **� Performance First**: Built for speed with Dart's native performance
- **🎯 Developer Experience**: Intuitive API with excellent tooling
- **🔧 Full Control**: No magic, complete control over your application
- **📈 Scalable**: Built to handle growth from prototype to production
- **🔒 Secure**: Security best practices built-in
- **🌍 Ecosystem**: Growing community and package ecosystem

---

## 📞 Support

- 🐛 [Bug Reports](https://github.com/khedrmahmoud/khadem/issues)
- 💡 [Feature Requests](https://github.com/khedrmahmoud/khadem/discussions)
- 💬 [Community Chat](https://discord.gg/khadem)
- 📧 [Email Support](mailto:support@khadem.dev)

---

**Built with ❤️ for the Dart community**
