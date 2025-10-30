import 'package:khadem/khadem.dart';
import '../requests/create_user_request.dart';

class UserController {
  /// Example of using FormRequest in a controller
  static Future<void> store(Request req, Response res) async {
    try {
      // Create the FormRequest instance and validate
      final validatedData = await CreateUserRequest().validate(req);

      // At this point, data is validated and processed
      // validatedData contains only the fields defined in rules()
      // plus any additional fields added in passedValidation()

      // Example: Create user (simplified)
      // final user = await User.create(validatedData);

      res.status(201).sendJson({
        'success': true,
        'message': 'User created successfully',
        'data': validatedData,
      });
    } on UnauthorizedException catch (e) {
      res.status(403).sendJson({
        'success': false,
        'message': e.message,
      });
    } on ValidationException catch (e) {
      res.status(422).sendJson({
        'success': false,
        'message': 'Validation failed',
        'errors': e.errors,
      });
    } catch (e) {
      res.status(500).sendJson({
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      });
    }
  }

  /// Alternative approach: using helper methods with instance
  static Future<void> update(Request req, Response res) async {
    try {
      final formRequest = CreateUserRequest();
      await formRequest.validate(req);

      // Access validated data
      final name = formRequest.validatedInput('name');
      final email = formRequest.validatedInput('email');

      // Or get specific fields
      final userData = formRequest.only(['name', 'email', 'role']);

      // Or exclude fields
      final userDataWithoutPassword =
          formRequest.except(['password', 'password_confirmation']);

      res.sendJson({
        'success': true,
        'name': name,
        'email': email,
        'userData': userData,
        'userDataWithoutPassword': userDataWithoutPassword,
      });
    } on ValidationException catch (e) {
      res.status(422).sendJson({
        'success': false,
        'errors': e.errors,
      });
    }
  }
}
