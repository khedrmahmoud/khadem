import '../lib/src/core/validation/enhanced_validator.dart';

void main() {
  print('🎯 Enhanced Validation System Examples');
  print('═════════════════════════════════════════');
  
  testBasicValidation();
  print('\n' + '═' * 50 + '\n');
  
  testFileUploadValidation();
  print('\n' + '═' * 50 + '\n');
  
  testNestedArrayValidation();
  print('\n' + '═' * 50 + '\n');
  
  testHelperMethods();
}

void testBasicValidation() {
  print('📋 Basic Validation Test');
  print('─────────────────────────');
  
  final data = {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 25,
    'website': null,
  };
  
  final rules = {
    'name': 'required|string|min:2',
    'email': 'required|email',
    'age': 'required|int|min:18',
    'website': 'nullable|url',
  };
  
  final validator = AdvancedInputValidator(data, rules);
  
  if (validator.passes()) {
    print('✅ Basic validation passed');
  } else {
    print('❌ Basic validation failed:');
    validator.errors.forEach((field, error) {
      print('   - $field: $error');
    });
  }
}

void testFileUploadValidation() {
  print('📎 File Upload Validation Test');
  print('───────────────────────────────');
  
  // Simulate file upload data
  final data = {
    'attachments': [
      UploadedFile(
        filename: 'document.pdf',
        size: 2048 * 1024, // 2MB
        mimeType: 'application/pdf',
        path: '/tmp/upload1',
      ),
      UploadedFile(
        filename: 'image.jpg',
        size: 1024 * 1024, // 1MB
        mimeType: 'image/jpeg',
        path: '/tmp/upload2',
      ),
      UploadedFile(
        filename: 'large_video.mp4',
        size: 10 * 1024 * 1024, // 10MB - should fail
        mimeType: 'video/mp4',
        path: '/tmp/upload3',
      ),
    ],
  };
  
  final rules = {
    'attachments': 'nullable|array',
    'attachments.*': 'file|max:5120', // Max 5MB per file
  };
  
  final validator = AdvancedInputValidator(data, rules);
  
  if (validator.passes()) {
    print('✅ File upload validation passed');
  } else {
    print('❌ File upload validation failed:');
    validator.errors.forEach((field, error) {
      print('   - $field: $error');
    });
  }
}

void testNestedArrayValidation() {
  print('🔗 Nested Array Validation Test');
  print('─────────────────────────────────');
  
  final data = {
    'users': [
      {
        'name': 'Alice',
        'email': 'alice@example.com',
        'profile': {
          'avatar': UploadedFile(
            filename: 'alice.jpg',
            size: 500 * 1024, // 500KB
            mimeType: 'image/jpeg',
            path: '/tmp/alice.jpg',
          ),
        },
      },
      {
        'name': 'Bob',
        'email': 'invalid-email', // Invalid email
        'profile': {
          'avatar': UploadedFile(
            filename: 'bob.png',
            size: 200 * 1024, // 200KB
            mimeType: 'image/png',
            path: '/tmp/bob.png',
          ),
        },
      },
    ],
  };
  
  final rules = {
    'users': 'required|array|min_items:1',
    'users.*.name': 'required|string|min:2',
    'users.*.email': 'required|email',
    // Note: Nested file validation like users.*.profile.avatar would need more complex implementation
  };
  
  final validator = AdvancedInputValidator(data, rules);
  
  if (validator.passes()) {
    print('✅ Nested array validation passed');
  } else {
    print('❌ Nested array validation failed:');
    validator.errors.forEach((field, error) {
      print('   - $field: $error');
    });
  }
}

void testHelperMethods() {
  print('🛠️  Helper Methods Test');
  print('─────────────────────');
  
  // Test file upload helper
  print('📎 File upload rules:');
  final fileRules = ValidatorHelpers.fileUploadRules(
    multiple: true,
    allowedMimes: ['jpg', 'jpeg', 'png', 'pdf'],
    maxSizeKB: 5120, // 5MB
    nullable: true,
  );
  
  fileRules.forEach((field, rule) {
    print('   $field: $rule');
  });
  
  print('\n📋 Array validation rules:');
  final arrayRules = ValidatorHelpers.arrayRules(
    'tags',
    'required|string|min:2',
    minItems: 1,
    maxItems: 10,
  );
  
  arrayRules.forEach((field, rule) {
    print('   $field: $rule');
  });
}

/// Mock UploadedFile class for demonstration
class UploadedFile {
  final String filename;
  final int size;
  final String mimeType;
  final String path;
  
  UploadedFile({
    required this.filename,
    required this.size,
    required this.mimeType,
    required this.path,
  });
  
  @override
  String toString() => 'UploadedFile($filename, ${(size / 1024).round()}KB)';
}
