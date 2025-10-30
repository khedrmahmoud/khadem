## 1.1.0-beta

### Major Features
- **Mail Module**: Complete email system with multiple transport drivers (SMTP, Mailgun, SES, Postmark, Log, Array)
  - Mailable classes for structured email composition
  - HTML and plain text email support
  - File attachments and inline images
  - Queue integration for async email sending
  - Comprehensive mail configuration system

- **Enhanced Queue System**: Advanced queue management with new features
  - Dead Letter Queue (DLQ) for failed job handling
  - Queue metrics and monitoring
  - Priority queue support
  - Job serialization and deduplication middleware
  - Multiple storage drivers (Redis, File, In-Memory, Synchronous)
  - Job registry for better job management

- **ORM Traits & Features**: Comprehensive ORM enhancements
  - ModelObserver with 12 lifecycle hooks (creating, created, updating, updated, saving, saved, deleting, deleted, retrieving, retrieved, restoring, restored, forceDeleting, forceDeleted)
  - Timestamps trait for automatic created_at/updated_at management
  - SoftDeletes trait with restore and force delete capabilities
  - HasSlug trait for URL-friendly slug generation
  - UuidPrimaryKey trait for UUID primary keys
  - QueryScopes trait for reusable query constraints
  - HasTranslations trait for multi-language model support

- **Form Request Validation**: Laravel-style form request validation
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
