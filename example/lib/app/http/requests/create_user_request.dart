import 'package:khadem/khadem.dart';

/// Example FormRequest for creating a user.
///
/// This demonstrates all the features of FormRequest including:
/// - Validation rules
/// - Custom error messages
/// - Data preparation before validation
/// - Post-validation processing
/// - Authorization checks
class CreateUserRequest extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'name': 'required|string|max:255',
      'email': 'required|email',
      'password': 'required|string|min:8|confirmed',
      'role': 'required|in:admin,user,moderator',
      'age': 'nullable|int|min:18|max:120',
    };
  }

  @override
  Map<String, String> messages() {
    return {
      'name.required': 'Please provide your name',
      'name.max': 'Name cannot exceed 255 characters',
      'email.required': 'Email address is required',
      'email.email': 'Please provide a valid email address',
      'password.required': 'Password is required',
      'password.min': 'Password must be at least 8 characters',
      'password.confirmed': 'Password confirmation does not match',
      'role.required': 'Please select a role',
      'role.in': 'Invalid role selected. Must be admin, user, or moderator',
      'age.min': 'You must be at least 18 years old',
      'age.max': 'Age cannot exceed 120',
    };
  }

  @override
  void prepareForValidation(Request request) {
    // You can access request data here
    // For modifying data, use passedValidation after validation
    final email = request.input('email');
    if (email != null) {
      // Log or perform checks before validation
      print('Validating email: $email');
    }
  }

  @override
  void passedValidation(Map<String, dynamic> validated) {
    // Modify validated data after successful validation
    // Trim and normalize email
    if (validated.containsKey('email')) {
      validated['email'] = validated['email'].toString().trim().toLowerCase();
    }

    // Trim name
    if (validated.containsKey('name')) {
      validated['name'] = validated['name'].toString().trim();
    }

    // Add timestamp
    validated['created_at'] = DateTime.now().toIso8601String();

    // In real implementation, hash the password:
    // validated['password'] = Hash.make(validated['password']);
  }

  @override
  bool authorize(Request request) {
    // Example: Only authenticated users can create other users
    // In real app: return request.user()?.isAdmin ?? false;

    // For demonstration, always allow
    return true;
  }
}
