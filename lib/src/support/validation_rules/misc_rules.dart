import '../../contracts/validation/rule.dart';

class UuidRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'uuid_validation';
    }

    if (value is! String) {
      return 'uuid_validation';
    }

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (!uuidRegex.hasMatch(value)) {
      return 'uuid_validation';
    }

    return null;
  }
}

class JsonRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'json_validation';
    }

    if (value is! String) {
      return 'json_validation';
    }

    try {
      // Try to parse as JSON
      // Note: In Dart, we can use json.decode but for validation purposes,
      // we'll do a basic check
      if (!value.trim().startsWith('{') && !value.trim().startsWith('[')) {
        return 'json_validation';
      }

      // Basic JSON structure validation
      final trimmed = value.trim();
      if ((trimmed.startsWith('{') && !trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && !trimmed.endsWith(']'))) {
        return 'json_validation';
      }

      return null;
    } catch (e) {
      return 'json_validation';
    }
  }
}

class PhoneRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'phone_validation';
    }

    if (value is! String) {
      return 'phone_validation';
    }

    // Basic international phone number regex
    // This is a simplified version - in production, you might want to use
    // a more comprehensive phone number validation library
    final phoneRegex = RegExp(
      r'^\+?[\d\s\-\(\)]{10,15}$',
    );

    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'phone_validation';
    }

    return null;
  }
}

class NullableRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    // Nullable rule always passes validation.
    // When used in combination with other rules, it indicates that null values are allowed
    // and other validation rules should be skipped if the field value is null.
    // The actual nullable logic is handled in the Validator class.
    return null;
  }
}

class SometimesRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    // Sometimes rule indicates that the field may or may not be present
    // This is typically used to make validation conditional
    return null;
  }
}

class ProhibitedRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    // Prohibited rule fails if the field is present
    return 'prohibited_validation';
  }
}

class ProhibitedIfRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (arg == null) {
      return 'prohibited_if_validation';
    }

    final parts = arg.split(',');
    if (parts.length < 2) {
      return 'prohibited_if_validation';
    }

    final otherField = parts[0];
    final expectedValue = parts[1];

    if (data.containsKey(otherField) && data[otherField].toString() == expectedValue) {
      return 'prohibited_if_validation';
    }

    return null;
  }
}

class RequiredIfRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (arg == null) {
      return null; // If no condition specified, don't enforce
    }

    final parts = arg.split(',');
    if (parts.length < 2) {
      return null;
    }

    final otherField = parts[0];
    final expectedValue = parts[1];

    if (data.containsKey(otherField) && data[otherField].toString() == expectedValue) {
      if (value == null || (value is String && value.isEmpty)) {
        return 'required_if_validation';
      }
    }

    return null;
  }
}
