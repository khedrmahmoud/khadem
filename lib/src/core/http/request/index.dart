/// Request handling components for the Khadem framework.
///
/// This library provides a clean, modular approach to handling HTTP requests
/// with proper separation of concerns.
///
/// ## Components
///
/// - [Request]: Main request class that composes all functionality
/// - [RequestBodyParser]: Handles parsing of request bodies
/// - [RequestValidator]: Handles validation of request data
/// - [RequestAuth]: Handles authentication-related functionality
/// - [RequestParams]: Handles parameter and attribute management
/// - [RequestHeaders]: Handles HTTP header operations
/// - [RequestHandler]: Type definition for request handler functions
/// - [UploadedFile]: Represents uploaded files in multipart requests
///
/// ## File Upload Usage
///
/// ```dart
/// // Single file upload
/// final avatar = request.file('avatar');
/// if (avatar != null) {
///   await avatar.saveTo('/uploads/avatars/${avatar.filename}');
/// }
///
/// // Multiple files with same field name
/// final images = request.filesByName('images');
/// for (final image in images) {
///   await image.saveTo('/uploads/images/${image.filename}');
/// }
///
/// // Check if file exists
/// if (request.hasFile('document')) {
///   final doc = request.firstFile('document');
///   // Process document
/// }
///
/// // Access form fields (automatically typed)
/// final name = request.body['name']; // String
/// final age = request.body['age']; // int
/// final isActive = request.body['is_active']; // bool
/// final tags = request.body['tags']; // List
/// ```

export 'request.dart';
export 'request_auth.dart';
export 'request_body_parser.dart';
export 'request_handler.dart';
export 'request_headers.dart';
export 'request_params.dart';
export 'request_validator.dart';
