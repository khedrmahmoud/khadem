## 1.2.0-beta

### 🚀 Performance & Stability
- **Zero-Allocation Middleware**: Optimized middleware pipeline execution to reduce memory allocation per request.
- **Cached Route Matching**: Implemented O(1) lookup for static routes and cached matching for dynamic routes.
- **Smart Static Serving**: Added support for `If-Modified-Since` headers and `304 Not Modified` responses for static files.
- **Auto-Healing Cluster**: Added supervisor logic to `ServerCluster` to automatically restart crashed worker isolates.
- **Concurrent Body Parsing**: Optimized `RequestBodyParser` to handle concurrent parsing requests efficiently using Futures.
- **Resource Cleanup**: Implemented automatic cleanup of temporary files (uploads) after request completion.

### ✨ New Features
- **Log Facade**: Added `Log` class for easy static access to logging (e.g., `Log.info()`, `Log.time()`).
- **Non-Blocking Logging**: `FileLogHandler` now uses `IOSink` for non-blocking asynchronous file writing.
- **Stream & Callback Logging**: Added `StreamLogHandler` and `CallbackLogHandler` for flexible log processing.
- **Security Middleware**: Added `SecurityHeadersMiddleware` and `RateLimitMiddleware` for enhanced security.
- **Streaming Uploads**: Large file uploads are now streamed directly to disk to minimize memory usage.

## 1.1.2-beta

### Bug Fixes, Refactors & Improvements
- **Server & Router**: Move route registration responsibility to the router and remove direct HTTP method helpers from `Server`.
  - `Server.injectRoutes((router) { ... })` provides an explicit, single-entrypoint for route registration.
  - Internal server fields renamed for clarity (e.g. `ServerRouter`, `ServerMiddleware`, `ServerLifecycle`).
  - Development-only endpoints (`/reload`, `/restart`) are injected by the server router only in development mode.
- **Docs & Cleanups**: Improved server docs, removed unused imports, and minor lint/format fixes.


## 1.1.1-beta

### Bug Fixes & Improvements
- **ServeCommand Refactor**: Complete overhaul of the development server command
  - Fixed PowerShell terminal hang issue (removed raw mode requirement)
  - Simplified error handling and removed complex retry logic
  - Improved error messages and user experience
  - Line-based input (press Enter after command) works on all platforms
  - Single VM service connection attempt with graceful fallback
  - Cleaner code structure (reduced from 400+ to ~250 lines)
  - Interactive commands: `r` (hot reload), `f` (full restart), `q` (quit)
  - Auto-reload on file changes with debouncing
  - Better process lifecycle management

### Technical Improvements
- Removed unnecessary state tracking (consecutive failures, initial start flags)
- Simplified VM service connection logic
- Better separation of concerns in server lifecycle
- Improved shutdown handling
- Cleaner error reporting

## 1.1.0-beta

### Major Features
- **Mail Module**: Complete email system with multiple transport drivers (SMTP, Mailgun, SES, Postmark, Log, Array)
  - Mailable classes for structured email composition
  - HTML and plain text email support
  - File attachments and inline images
  - Queue integration for async email sending
  - Comprehensive mail configuration system

-- **Enhanced Queue System**: Advanced queue management with new features
  - Dead Letter Queue (DLQ) for failed job handling
  - Queue metrics and monitoring
  - Priority queue support
  - Job serialization and deduplication middleware
  - Multiple storage drivers (Redis, File, In-Memory, Synchronous)
  - Job registry for better job management

-- **ORM Traits & Features**: Comprehensive ORM enhancements
  - ModelObserver with 12 lifecycle hooks (creating, created, updating, updated, saving, saved, deleting, deleted, retrieving, retrieved, restoring, restored, forceDeleting, forceDeleted)
  - Timestamps trait for automatic created_at/updated_at management
  - SoftDeletes trait with restore and force delete capabilities
  - HasSlug trait for URL-friendly slug generation
  - UuidPrimaryKey trait for UUID primary keys
  - QueryScopes trait for reusable query constraints
  - HasTranslations trait for multi-language model support

-- **Form Request Validation**: Laravel-style form request validation
  - Dedicated request validation classes
  - Authorization logic separation
  - Automatic validation error responses

### Improvements
- Enhanced database model system with better event handling
- Improved session management with multiple driver support
- Better HTTP request parsing and validation
- Enhanced authentication system with multi-device support
- Comprehensive documentation at https://khadem-framework.github.io/khadem-docs/

### Code Quality
- Applied code formatting across entire codebase (502 files formatted, 128 fixes applied)
- Fixed HTML angle bracket interpretation in documentation comments
- Improved code quality with trailing commas and directive ordering
- Reduced analysis warnings from 13 to 9 (all info-level)

### Documentation
- Added comprehensive ORM traits documentation
- Added Mail module documentation with driver-specific guides
- Enhanced database and models documentation
- Added Queue system documentation with examples
- Improved API documentation throughout the framework

## 1.0.4-beta
- Added comprehensive documentation to EagerLoader class with detailed method descriptions
- Updated LICENSE file with GitHub repository links for better discoverability

## 1.0.3-beta
- Fixed migrator database configuration to use config system instead of environment variables
- Updated `_ensureDatabaseExists()` method to use `Khadem.config.get('database.database')` for better consistency

## 1.0.2-beta
- Updated project structure documentation to reflect actual file layout
- Fixed README.md project structure to match real implementation
- Corrected documentation paths (lib/routes/, lib/config/, lib/core/)
- Updated CLI commands documentation with proper file generation paths
- Fixed creating-project.vue duplicate entries and path references
- Enhanced installation documentation with beta version notes

## 1.0.1-beta
- Fixed static analysis issues for perfect score
- Removed dangling library doc comments
- Fixed HTML angle bracket interpretation in documentation


## 1.0.0-beta
- Initial beta release
- Core framework features included

```
