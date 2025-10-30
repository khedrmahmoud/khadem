<div align="center">
  <img src="assets/logo.png" alt="Khadem Framework" width="120" height="120">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/status-beta-yellow" alt="Status">
  <img src="https://img.shields.io/badge/version-1.1.0--beta-blue" alt="Version">
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