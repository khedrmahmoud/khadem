import 'dart:async';

import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/support/exceptions/unauthorized_exception.dart';
import 'package:khadem/src/support/exceptions/validation_exception.dart';

/// FormRequest provides a clean, reusable way to encapsulate validation logic,
/// authorization checks, and data preparation for HTTP requests.
///
/// FormRequest classes are designed to be used with controllers to separate
/// validation concerns from business logic. They provide a standardized way
/// to handle form submissions with proper error handling and data transformation.
///
/// ## Basic Usage
///
/// ```dart
/// class CreateUserRequest extends FormRequest {
///   @override
///   Map<String, String> rules() {
///     return {
///       'name': 'required|string|max:255',
///       'email': 'required|email|unique:users',
///       'password': 'required|min:8|confirmed',
///     };
///   }
///
///   @override
///   Map<String, String> messages() {
///     return {
///       'email.unique': 'This email is already taken',
///       'password.confirmed': 'Password confirmation does not match',
///     };
///   }
///
///   @override
///   bool authorize(Request request) {
///     return request.user()?.can('create-users') ?? false;
///   }
///
///   @override
///   void passedValidation(Map<String, dynamic> validated) {
///     // Hash password after validation
///     validated['password'] = Hash.make(validated['password']);
///     validated['created_at'] = DateTime.now().toIso8601String();
///   }
/// }
///
/// // In controller:
/// static Future<void> store(Request req, Response res) async {
///   try {
///     final validated = await CreateUserRequest().validate(req);
///     final user = await User.create(validated);
///     res.status(201).sendJson({'user': user});
///   } on UnauthorizedException catch (e) {
///     res.status(403).sendJson({'error': e.message});
///   } on ValidationException catch (e) {
///     res.status(422).sendJson({'errors': e.errors});
///   }
/// }
/// ```
///
/// ## Lifecycle
///
/// FormRequest follows a specific lifecycle when `validate()` is called:
///
/// 1. **Authorization Check**: `authorize()` is called first
///    - If it returns `false`, an `UnauthorizedException` is thrown
///    - If it returns `true`, validation continues
///
/// 2. **Preparation**: `prepareForValidation()` is called
///    - Use this to modify or clean input data before validation
///    - Changes made here affect validation but not the final validated data
///
/// 3. **Validation**: The request's `validate()` method is called
///    - Uses the rules from `rules()` and messages from `messages()`
///    - Throws `ValidationException` if validation fails
///
/// 4. **Post-Validation**: `passedValidation()` is called
///    - Use this to transform validated data (hashing passwords, etc.)
///    - Changes made here are included in the final validated data
///
/// ## Available Methods
///
/// ### Abstract Methods (Must Override)
///
/// #### `rules()` - Required
/// Define validation rules for the request.
///
/// ```dart
/// @override
/// Map<String, String> rules() {
///   return {
///     'field_name': 'required|email|max:255',
///   };
/// }
/// ```
///
/// ### Optional Methods
///
/// #### `messages()`
/// Define custom error messages for validation rules.
///
/// ```dart
/// @override
/// Map<String, String> messages() {
///   return {
///     'email.required': 'Please provide your email address',
///     'password.min': 'Password must be at least 8 characters',
///   };
/// }
/// ```
///
/// #### `authorize(Request request)`
/// Check if the user is authorized to make this request.
///
/// ```dart
/// @override
/// bool authorize(Request request) {
///   return request.user()?.isAdmin ?? false;
/// }
/// ```
///
/// #### `prepareForValidation(Request request)`
/// Prepare the request data for validation.
///
/// ```dart
/// @override
/// void prepareForValidation(Request request) {
///   // Trim whitespace, normalize data, etc.
///   // Note: Request class may not have merge() method
/// }
/// ```
///
/// #### `passedValidation(Map<String, dynamic> validated)`
/// Process data after successful validation.
///
/// ```dart
/// @override
/// void passedValidation(Map<String, dynamic> validated) {
///   validated['password'] = Hash.make(validated['password']);
///   validated['created_at'] = DateTime.now().toIso8601String();
/// }
/// ```
///
/// #### `failedValidation(Map<String, String> errors)`
/// Handle validation failure. Default behavior throws ValidationException.
///
/// ```dart
/// @override
/// void failedValidation(Map<String, String> errors) {
///   // Log errors, send notifications, etc.
///   logger.warning('Validation failed', errors);
///   super.failedValidation(errors); // Re-throws the exception
/// }
/// ```
///
/// ## Helper Methods
///
/// ### `validatedData`
/// Get all validated data after validation.
///
/// ```dart
/// final data = formRequest.validatedData;
/// ```
///
/// ### `validatedInput(key, {defaultValue})`
/// Get a specific validated field value.
///
/// ```dart
/// final email = formRequest.validatedInput('email');
/// final name = formRequest.validatedInput('name', defaultValue: 'Guest');
/// ```
///
/// ### `only(List<String> keys)`
/// Get only specified fields from validated data.
///
/// ```dart
/// final credentials = formRequest.only(['email', 'password']);
/// ```
///
/// ### `except(List<String> keys)`
/// Get all validated data except specified fields.
///
/// ```dart
/// final safeData = formRequest.except(['password', 'token']);
/// ```
///
/// ### `hasValidated()`
/// Check if validation has been performed.
///
/// ```dart
/// if (formRequest.hasValidated()) {
///   // Safe to access validated data
/// }
/// ```
///
/// ### `request`
/// Get the underlying Request instance.
///
/// ```dart
/// final originalRequest = formRequest.request;
/// ```
///
/// ## Exception Handling
///
/// ### ValidationException
/// Thrown when validation fails. Contains field-specific error messages.
///
/// ```dart
/// try {
///   await CreateUserRequest().validate(req);
/// } on ValidationException catch (e) {
///   // e.errors is Map<String, String> of field => error message
///   res.status(422).sendJson({'errors': e.errors});
/// }
/// ```
///
/// ### UnauthorizedException
/// Thrown when `authorize()` returns false.
///
/// ```dart
/// try {
///   await CreateUserRequest().validate(req);
/// } on UnauthorizedException catch (e) {
///   res.status(403).sendJson({'error': e.message});
/// }
/// ```
///
/// ## Testing
///
/// ```dart
/// test('validates user creation', () async {
///   final request = createTestRequest({
///     'name': 'John Doe',
///     'email': 'john@example.com',
///     'password': 'password123',
///   });
///
///   final formRequest = CreateUserRequest();
///   final validated = await formRequest.validate(request);
///
///   expect(validated['name'], equals('John Doe'));
///   expect(validated['email'], equals('john@example.com'));
/// });
///
/// test('fails validation with invalid data', () async {
///   final request = createTestRequest({
///     'name': '',
///     'email': 'invalid-email',
///   });
///
///   final formRequest = CreateUserRequest();
///
///   expect(
///     () => formRequest.validate(request),
///     throwsA(isA<ValidationException>()),
///   );
/// });
/// ```
///
/// ## Best Practices
///
/// 1. **Keep FormRequests Focused**: One FormRequest per action
/// 2. **Use Authorization**: Always implement `authorize()` for security
/// 3. **Provide Custom Messages**: User-friendly error messages improve UX
/// 4. **Normalize in passedValidation**: Clean and transform data after validation
/// 5. **Test Thoroughly**: Write tests for validation rules and authorization
/// 6. **Document Complex Rules**: Add comments for complex validation logic
/// 7. **Handle Files Properly**: Use appropriate file validation rules
/// 8. **Use Helper Methods**: Leverage `only()`, `except()` for data manipulation
abstract class FormRequest {
  /// The original [Request] instance that was validated.
  ///
  /// This field is set during the [validate] method and contains the
  /// request that was passed for validation. It can be used to access
  /// additional request data or methods that may be needed after validation.
  ///
  /// Returns `null` if validation has not been performed yet.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void passedValidation(Map<String, dynamic> validated) {
  ///   // Access original request data
  ///   final userAgent = request?.header('User-Agent');
  ///   validated['user_agent'] = userAgent;
  /// }
  /// ```
  Request? _request;

  /// The validated data after successful validation.
  ///
  /// This field contains the data that passed all validation rules.
  /// It is set during the [validate] method after the request's validate()
  /// method completes successfully. The data may be modified by the
  /// [passedValidation] hook.
  ///
  /// Returns `null` if validation has not been performed or failed.
  ///
  /// Example:
  /// ```dart
  /// // After calling validate()
  /// final name = _validatedData?['name'];
  /// final email = _validatedData?['email'];
  /// ```
  Map<String, dynamic>? _validatedData;

  /// Define the validation rules for this request.
  ///
  /// This abstract method must be implemented by subclasses to specify
  /// the validation rules that should be applied to the request data.
  ///
  /// Returns a [Map] where keys are field names and values are validation
  /// rule strings. Multiple rules can be combined using the pipe `|` character.
  ///
  /// Common validation rules include:
  /// - `required` - Field must be present and not empty
  /// - `email` - Field must be a valid email address
  /// - `min:N` - Field must be at least N characters/numbers
  /// - `max:N` - Field must not exceed N characters
  /// - `string` - Field must be a string
  /// - `numeric` - Field must be numeric
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, String> rules() {
  ///   return {
  ///     'name': 'required|string|max:255',
  ///     'email': 'required|email',
  ///     'age': 'required|numeric|min:18|max:120',
  ///     'password': 'required|min:8',
  ///   };
  /// }
  /// ```
  ///
  /// Returns: A map of field names to validation rule strings.
  Map<String, String> rules();

  /// Define custom error messages for validation rules.
  ///
  /// Override this method to provide user-friendly error messages for
  /// specific validation failures. If not overridden, default error
  /// messages will be used.
  ///
  /// The message keys follow the pattern `field.rule` or `field.rule:parameter`.
  /// You can also use wildcards like `*.required` for general messages.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, String> messages() {
  ///   return {
  ///     'name.required': 'Please provide your full name',
  ///     'email.required': 'We need your email address to contact you',
  ///     'email.email': 'Please enter a valid email address',
  ///     'password.min': 'Your password must be at least 8 characters long',
  ///     'age.min': 'You must be at least 18 years old to register',
  ///     '*.required': 'This field is required',
  ///   };
  /// }
  /// ```
  ///
  /// Returns: A map of validation rule keys to custom error messages.
  /// Defaults to an empty map if not overridden.
  Map<String, String> messages() => {};

  /// Prepare the request data for validation.
  ///
  /// This hook is called after authorization but before validation rules
  /// are applied. Use it to clean, normalize, or modify the request data
  /// before validation occurs.
  ///
  /// Changes made here affect the validation process but do not appear
  /// in the final validated data. For data transformation after validation,
  /// use [passedValidation] instead.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void prepareForValidation(Request request) {
  ///   // Trim whitespace from string fields
  ///   // Note: This is a conceptual example - actual implementation
  ///   // depends on the Request class's available methods
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [request]: The request instance being validated
  Future<void> prepareForValidation(Request request) async {}

  /// Process data after successful validation.
  ///
  /// This hook is called after validation passes but before the validated
  /// data is returned. Use it to transform, hash, or enrich the validated data.
  ///
  /// Changes made to the [validated] map will be included in the final
  /// result returned by [validate].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void passedValidation(Map<String, dynamic> validated) {
  ///   // Hash the password
  ///   validated['password'] = Hash.make(validated['password']);
  ///
  ///   // Add timestamps
  ///   validated['created_at'] = DateTime.now().toIso8601String();
  ///   validated['updated_at'] = validated['created_at'];
  ///
  ///   // Normalize data
  ///   validated['email'] = validated['email'].toLowerCase();
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [validated]: The validated data map that can be modified
  void passedValidation(Map<String, dynamic> validated) {}

  /// Handle validation failure.
  ///
  /// This hook is called when validation fails. The default implementation
  /// re-throws the [ValidationException], but you can override this method
  /// to perform additional actions like logging, notifications, or custom
  /// error handling before re-throwing.
  ///
  /// If you override this method, you should typically call
  /// `super.failedValidation(errors)` to maintain the expected behavior
  /// of throwing the exception.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void failedValidation(Map<String, String> errors) {
  ///   // Log validation failures
  ///   logger.warning('Validation failed for ${request?.uri.path}', {
  ///     'errors': errors,
  ///     'user_id': request?.user()?.id,
  ///     'ip': request?.ip(),
  ///   });
  ///
  ///   // Send to monitoring service
  ///   monitoring.track('validation_failed', {
  ///     'field_count': errors.length,
  ///     'request_path': request?.uri.path,
  ///   });
  ///
  ///   // Re-throw the exception
  ///   super.failedValidation(errors);
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [errors]: A map of field names to error messages
  ///
  /// Throws: [ValidationException] (by default implementation)
  void failedValidation(Map<String, String> errors) {
    throw ValidationException(errors);
  }

  /// Determine if the user is authorized to make this request.
  ///
  /// This method is called before validation to check if the current user
  /// has permission to perform the action. Return `true` to allow the request,
  /// or `false` to deny it.
  ///
  /// The default implementation returns `true`, allowing all requests.
  /// Override this method to implement authorization logic.
  ///
  /// If this method returns `false`, an [UnauthorizedException] will be
  /// thrown immediately, before any validation occurs.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool authorize(Request request) {
  ///   final user = request.user();
  ///   if (user == null) return false;
  ///
  ///   // Check user permissions
  ///   return user.can('create-posts') || user.hasRole('admin');
  /// }
  ///
  /// // Or check request parameters
  /// @override
  /// bool authorize(Request request) {
  ///   final postId = request.input('post_id');
  ///   if (postId != null) {
  ///     final post = Post.find(postId);
  ///     return post?.user_id == request.user()?.id;
  ///   }
  ///   return true;
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [request]: The request instance being validated
  ///
  /// Returns: `true` if the request is authorized, `false` otherwise
  bool authorize(Request request) => true;

  /// Validate the request using the defined rules and authorization.
  ///
  /// This is the main method that orchestrates the entire FormRequest lifecycle:
  /// 1. Stores the request reference
  /// 2. Checks authorization via [authorize]
  /// 3. Calls [prepareForValidation] for data preparation
  /// 4. Performs validation using the request's validate method
  /// 5. Calls [passedValidation] for post-validation processing
  /// 6. Handles validation failures via [failedValidation]
  ///
  /// The method returns the validated and processed data, or throws an
  /// exception if validation or authorization fails.
  ///
  /// Example:
  /// ```dart
  /// // In a controller
  /// static Future<void> store(Request req, Response res) async {
  ///   try {
  ///     final formRequest = CreateUserRequest();
  ///     final validated = await formRequest.validate(req);
  ///
  ///     final user = await User.create(validated);
  ///     res.status(201).sendJson({'user': user});
  ///   } on UnauthorizedException catch (e) {
  ///     res.status(403).sendJson({'error': e.message});
  ///   } on ValidationException catch (e) {
  ///     res.status(422).sendJson({'errors': e.errors});
  ///   }
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [request]: The request instance to validate
  ///
  /// Returns: A [Future] that completes with the validated data map
  ///
  /// Throws:
  /// - [UnauthorizedException] if [authorize] returns `false`
  /// - [ValidationException] if validation fails
  Future<Map<String, dynamic>> validate(Request request) async {
    _request = request;
    if (!authorize(request)) {
      throw UnauthorizedException('This action is unauthorized.');
    }
    await prepareForValidation(request);
    try {
      _validatedData = await request.validate(rules(), messages: messages());
      passedValidation(_validatedData!);
      return _validatedData!;
    } catch (e) {
      if (e is ValidationException) {
        failedValidation(e.errors);
      }
      rethrow;
    }
  }

  /// Merges values into the request body.
  ///
  /// This is useful in [prepareForValidation] to normalize data.
  void merge(Map<String, dynamic> values) {
    _request?.merge(values);
  }

  /// Get all validated data after successful validation.
  ///
  /// Returns the complete validated data map that was produced by the
  /// [validate] method. This includes any modifications made by
  /// [passedValidation].
  ///
  /// Throws [StateError] if validation has not been performed yet.
  Map<String, dynamic> validated() {
    if (_validatedData == null) {
      throw StateError('Validation has not been performed yet.');
    }
    return _validatedData!;
  }

  /// Get all validated data after successful validation.
  ///
  /// Returns the complete validated data map that was produced by the
  /// [validate] method. This includes any modifications made by
  /// [passedValidation].
  ///
  /// Returns `null` if validation has not been performed yet or if
  /// validation failed.
  ///
  /// Example:
  /// ```dart
  /// final formRequest = CreateUserRequest();
  /// await formRequest.validate(request);
  ///
  /// final allData = formRequest.validatedData;
  /// print('Validated: $allData');
  /// ```
  ///
  /// Returns: The validated data map, or `null` if not validated
  Map<String, dynamic>? get validatedData => _validatedData;

  /// Get a specific validated field value.
  ///
  /// Retrieves the value of a single field from the validated data.
  /// If the field is not present in the validated data, returns the
  /// [defaultValue] if provided, otherwise returns `null`.
  ///
  /// This method provides safe access to validated fields without
  /// needing to check if validation was successful first.
  ///
  /// Example:
  /// ```dart
  /// final formRequest = CreateUserRequest();
  /// await formRequest.validate(request);
  ///
  /// final name = formRequest.validatedInput('name');
  /// final email = formRequest.validatedInput('email');
  /// final nickname = formRequest.validatedInput('nickname', defaultValue: 'Anonymous');
  /// ```
  ///
  /// Parameters:
  /// - [key]: The field name to retrieve
  /// - [defaultValue]: Value to return if the field is not present
  ///
  /// Returns: The field value, default value, or `null`
  dynamic validatedInput(String key, {dynamic defaultValue}) {
    return _validatedData?[key] ?? defaultValue;
  }

  /// Get only the specified fields from validated data.
  ///
  /// Creates a new map containing only the fields specified in [keys].
  /// Fields that don't exist in the validated data are simply omitted
  /// from the result (no errors are thrown).
  ///
  /// This is useful for extracting a subset of validated data for
  /// specific operations, like passing only certain fields to a model.
  ///
  /// Example:
  /// ```dart
  /// final formRequest = CreateUserRequest();
  /// await formRequest.validate(request);
  ///
  /// // Get only login credentials
  /// final credentials = formRequest.only(['email', 'password']);
  /// await Auth.attempt(credentials);
  ///
  /// // Get only profile fields
  /// final profile = formRequest.only(['name', 'bio', 'avatar']);
  /// await user.updateProfile(profile);
  /// ```
  ///
  /// Parameters:
  /// - [keys]: List of field names to include in the result
  ///
  /// Returns: A new map containing only the specified fields
  Map<String, dynamic> only(List<String> keys) {
    if (_validatedData == null) return {};
    final result = <String, dynamic>{};
    for (final key in keys) {
      if (_validatedData!.containsKey(key)) {
        result[key] = _validatedData![key];
      }
    }
    return result;
  }

  /// Get all validated data except the specified fields.
  ///
  /// Creates a new map containing all validated fields except those
  /// specified in [keys]. This is the inverse of [only].
  ///
  /// Useful for excluding sensitive fields like passwords when logging
  /// or returning data, or for separating different types of data.
  ///
  /// Example:
  /// ```dart
  /// final formRequest = CreateUserRequest();
  /// await formRequest.validate(request);
  ///
  /// // Exclude sensitive data for logging
  /// final safeData = formRequest.except(['password', 'token']);
  /// logger.info('User created', safeData);
  ///
  /// // Separate profile and auth data
  /// final profileData = formRequest.except(['password', 'password_confirmation']);
  /// final authData = formRequest.only(['email', 'password']);
  /// ```
  ///
  /// Parameters:
  /// - [keys]: List of field names to exclude from the result
  ///
  /// Returns: A new map containing all fields except the specified ones
  Map<String, dynamic> except(List<String> keys) {
    if (_validatedData == null) return {};
    final result = Map<String, dynamic>.from(_validatedData!);
    for (final key in keys) {
      result.remove(key);
    }
    return result;
  }

  /// Check if validation has been performed successfully.
  ///
  /// Returns `true` if the [validate] method has completed successfully
  /// and validated data is available. Returns `false` if validation
  /// has not been performed yet or if it failed.
  ///
  /// This is useful for conditional logic that depends on whether
  /// validation has occurred.
  ///
  /// Example:
  /// ```dart
  /// final formRequest = CreateUserRequest();
  ///
  /// if (formRequest.hasValidated()) {
  ///   final name = formRequest.validatedInput('name');
  ///   print('Validated name: $name');
  /// } else {
  ///   print('Validation not performed yet');
  /// }
  ///
  /// await formRequest.validate(request);
  ///
  /// if (formRequest.hasValidated()) {
  ///   final email = formRequest.validatedInput('email');
  ///   print('Validated email: $email');
  /// }
  /// ```
  ///
  /// Returns: `true` if validation was successful, `false` otherwise
  bool hasValidated() => _validatedData != null;

  /// Get the original request instance that was validated.
  ///
  /// Returns the [Request] instance that was passed to the [validate]
  /// method. This can be used to access additional request data or
  /// methods that may be needed after validation.
  ///
  /// Returns `null` if validation has not been performed yet.
  ///
  /// Example:
  /// ```dart
  /// final formRequest = CreateUserRequest();
  /// await formRequest.validate(request);
  ///
  /// // Access request data
  /// final userAgent = formRequest.request?.header('User-Agent');
  /// final ip = formRequest.request?.ip();
  /// final method = formRequest.request?.method;
  /// ```
  ///
  /// Returns: The original request instance, or `null` if not validated
  Request? get request => _request;
}
