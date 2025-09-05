# Enhanced Validation System - Laravel-style Nested Validation

## Overview

The Enhanced Validation System brings Laravel-style validation to the Khadem framework, with full support for:

- **Nested field validation** (`attachments.*`, `users.*.email`)
- **File upload validation** with size and type restrictions  
- **Array validation** with item-level rules
- **Helper methods** for common validation patterns

## Key Features

### 1. Laravel-Style Syntax
```dart
final rules = {
  'attachments': 'nullable|array',
  'attachments.*': 'file|max:5120|mimes:pdf,jpg,png',
  'tags': 'required|array|min_items:1',
  'tags.*': 'string|min:2|max:20',
};
```

### 2. Nested Field Validation
The system supports wildcards (`*`) to validate array elements:

```dart
// Validate each user in an array
'users': 'required|array',
'users.*.name': 'required|string|min:2',
'users.*.email': 'required|email',
'users.*.age': 'nullable|int|min:13',
```

### 3. File Upload Validation
Full support for file validation with size, type, and multiple file handling:

```dart
final rules = {
  'avatar': 'required|file|image|max:2048',  // Single image, max 2MB
  'documents': 'nullable|array',
  'documents.*': 'file|mimes:pdf,doc,docx|max:10240', // Multiple docs, max 10MB each
};
```

### 4. Helper Methods
Pre-built helper methods for common validation scenarios:

```dart
// File upload validation helper
final rules = ValidatorHelpers.fileUploadRules(
  multiple: true,
  allowedMimes: ['jpg', 'jpeg', 'png', 'pdf'],
  maxSizeKB: 5120, // 5MB
  nullable: true,
);
// Result: {'attachments': 'nullable|array', 'attachments.*': 'file|mimes:jpg,jpeg,png,pdf|max:5120'}

// Array validation helper  
final rules = ValidatorHelpers.arrayRules(
  'tags',
  'required|string|min:2',
  minItems: 1,
  maxItems: 10,
);
// Result: {'tags': 'required|array|min_items:1|max_items:10', 'tags.*': 'required|string|min:2'}
```

## Usage Examples

### Basic File Upload
```dart
final requestData = {
  'title': 'Document Upload',
  'files': [uploadedFile1, uploadedFile2],
};

final rules = {
  'title': 'required|string|min:3',
  'files': 'required|array|max_items:5',
  'files.*': 'file|max:5120|mimes:pdf,doc,jpg,png',
};

final validator = EnhancedValidator(requestData, rules);
validator.validate(); // Throws ValidationException if validation fails
```

### Profile Upload with Validation
```dart
class ProfileController {
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final rules = ValidatorHelpers.fileUploadRules(
      multiple: false,
      allowedMimes: ['jpg', 'jpeg', 'png'],
      maxSizeKB: 2048,
      required: false,
      nullable: true,
    );
    
    rules['bio'] = 'nullable|string|max:500';
    rules['website'] = 'nullable|url';
    
    final validator = EnhancedValidator(data, rules);
    validator.validate();
    
    // Process validated data...
  }
}
```

### Complex Nested Validation
```dart
final documentBatchRules = {
  // User info
  'user_id': 'required|int|min:1',
  'category': 'required|string|in:legal,financial,personal',
  
  // Document array validation
  'documents': 'required|array|min_items:1|max_items:10',
  'documents.*.title': 'required|string|min:3|max:100',
  'documents.*.file': 'required|file|max:10240|mimes:pdf,doc,docx',
  'documents.*.confidential': 'nullable|bool',
  'documents.*.expires_at': 'nullable|date|after:today',
  
  // Optional metadata  
  'metadata': 'nullable|array',
  'metadata.project_id': 'nullable|int|min:1',
  'metadata.tags': 'nullable|array',
  'metadata.tags.*': 'string|min:2|max:30',
};
```

## Available Validation Rules

### File Rules
- `file` - Must be an uploaded file
- `image` - Must be an image file  
- `mimes:jpg,png,pdf` - Must match specified MIME types
- `max:5120` - Maximum file size in KB
- `min:1024` - Minimum file size in KB

### Array Rules  
- `array` - Must be an array
- `min_items:1` - Minimum number of array items
- `max_items:10` - Maximum number of array items
- `distinct` - All array items must be unique

### Standard Rules
- `required` - Field is required
- `nullable` - Field can be null
- `string` - Must be a string
- `int` - Must be an integer
- `email` - Must be valid email
- `url` - Must be valid URL
- `min:5` - Minimum length/value
- `max:100` - Maximum length/value
- `in:option1,option2` - Must be one of specified values

## Integration with HTTP Requests

### In a Route Handler
```dart
// routes/web.dart
router.post('/upload', (Request request) async {
  final validator = EnhancedValidator(
    await request.body(), 
    {
      'title': 'required|string|min:3',
      'files': 'required|array|max_items:5', 
      'files.*': 'file|max:5120|mimes:pdf,jpg,png',
    }
  );
  
  try {
    validator.validate();
    // Process validated data
    return Response.json({'success': true});
  } on ValidationException catch (e) {
    return Response.json({'errors': e.errors}, 422);
  }
});
```

### With Form Requests
```dart
class FileUploadRequest extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'attachments': 'nullable|array|max_items:5',
      'attachments.*': 'file|max:5120|mimes:pdf,doc,docx,jpg,jpeg,png',
      'description': 'nullable|string|max:1000',
    };
  }
}
```

## Error Handling

The system provides detailed error messages for validation failures:

```dart
try {
  validator.validate();
} on ValidationException catch (e) {
  // e.errors contains field => error message mapping
  print('Validation failed:');
  e.errors.forEach((field, message) {
    print('- $field: $message');
  });
  
  // Example output:
  // - attachments.0: The file is too large (3MB). Maximum allowed size is 2MB.
  // - attachments.2: Invalid file type. Allowed types: pdf, jpg, png.
  // - title: The title field is required.
}
```

## Implementation Notes

### Current Limitations
1. **Language Support**: Error messages currently return message keys instead of formatted text. This requires proper language file setup.

2. **File Size Validation**: The `max` rule needs to be properly mapped to `MaxFileSizeRule` in the validation registry.

3. **Deep Nested Validation**: Complex patterns like `users.*.profile.*.settings.*` need additional implementation.

### Planned Enhancements
1. Better error message formatting with proper language support
2. Conditional validation rules (`required_if`, `required_unless`)  
3. Custom validation rule registration
4. Validation rule caching for better performance
5. Integration with database validation (unique, exists)

## Configuration

To enable the enhanced validation system:

1. **Update the validation registry** to include all file rules:
```dart
// In rule_registry.dart, add:
'max_file_size': () => MaxFileSizeRule(),
```

2. **Set up language files** for proper error message formatting.

3. **Update request parsing** to properly handle file uploads with the `UploadedFile` class.

The system is designed to be backwards compatible with existing validation while providing powerful new features for complex validation scenarios.
