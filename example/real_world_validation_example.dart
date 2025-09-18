import '../lib/src/core/validation/enhanced_validator.dart';
import '../lib/src/support/exceptions/validation_exception.dart';

/// Real-world example showing how to use enhanced validation in HTTP controllers
class FileUploadController {
  
  /// Handle multiple file upload with validation
  Future<Map<String, dynamic>> handleMultipleFileUpload(Map<String, dynamic> requestData) async {
    try {
      final rules = {
        'title': 'required|string|min:3|max:100',
        'description': 'nullable|string|max:500',
        'attachments': 'nullable|array|max_items:5',
        'attachments.*': 'file|max:5120|mimes:pdf,doc,docx,jpg,jpeg,png',
        'tags': 'nullable|array',
        'tags.*': 'string|min:2|max:20',
      };
      
      // Validate the request
      final validator = AdvancedInputValidator(requestData, rules);
      validator.validate(); // Throws ValidationException if fails
      
      print('✅ File upload validation passed');
      
      // Process the validated data
      return _processFileUpload(requestData);
      
    } on ValidationException catch (e) {
      print('❌ Validation failed:');
      e.errors.forEach((field, error) {
        print('   - $field: $error');
      });
      rethrow;
    }
  }
  
  /// Handle profile image upload
  Future<Map<String, dynamic>> handleProfileImageUpload(Map<String, dynamic> requestData) async {
    // Using helper method for common file validation patterns
    final rules = ValidatorHelpers.fileUploadRules(
      allowedMimes: ['jpg', 'jpeg', 'png', 'gif'],
      maxSizeKB: 2048, // 2MB max
    );
    
    // Add additional rules
    rules['alt_text'] = 'nullable|string|max:100';
    
    final validator = AdvancedInputValidator(requestData, rules);
    
    if (validator.passes()) {
      print('✅ Profile image validation passed');
      return _processProfileImage(requestData);
    } else {
      print('❌ Profile image validation failed:');
      validator.errors.forEach((field, error) {
        print('   - $field: $error');
      });
      throw ValidationException(validator.errors);
    }
  }
  
  /// Handle document batch upload with complex rules
  Future<Map<String, dynamic>> handleDocumentBatch(Map<String, dynamic> requestData) async {
    final rules = {
      // User information
      'user_id': 'required|int|min:1',
      'category': 'required|string|in:legal,financial,personal',
      
      // Documents array validation
      'documents': 'required|array|min_items:1|max_items:10',
      'documents.*.title': 'required|string|min:3|max:100',
      'documents.*.file': 'required|file|max:10240|mimes:pdf,doc,docx', // 10MB max
      'documents.*.is_confidential': 'nullable|bool',
      'documents.*.expires_at': 'nullable|date|after:today',
      
      // Optional metadata
      'metadata': 'nullable|array',
      'metadata.project_id': 'nullable|int|min:1',
      'metadata.reference_number': 'nullable|string|alpha_num',
    };
    
    final validator = AdvancedInputValidator(requestData, rules);
    
    try {
      validator.validate();
      print('✅ Document batch validation passed');
      return _processDocumentBatch(requestData);
    } on ValidationException catch (e) {
      print('❌ Document batch validation failed:');
      e.errors.forEach((field, error) {
        print('   - $field: $error');
      });
      rethrow;
    }
  }
  
  // Private helper methods
  Map<String, dynamic> _processFileUpload(Map<String, dynamic> data) {
    // Simulate file processing
    print('📁 Processing file upload...');
    final attachments = data['attachments'] as List<UploadedFile>?;
    
    return {
      'success': true,
      'message': 'Files uploaded successfully',
      'files_count': attachments?.length ?? 0,
    };
  }
  
  Map<String, dynamic> _processProfileImage(Map<String, dynamic> data) {
    print('🖼️  Processing profile image...');
    return {
      'success': true,
      'message': 'Profile image updated successfully',
    };
  }
  
  Map<String, dynamic> _processDocumentBatch(Map<String, dynamic> data) {
    print('📚 Processing document batch...');
    final documents = data['documents'] as List<Map<String, dynamic>>;
    
    return {
      'success': true,
      'message': 'Document batch processed successfully',
      'documents_processed': documents.length,
    };
  }
}

/// Example usage in a route handler
void main() async {
  print('🚀 Enhanced Validation - Real World Examples');
  print('═══════════════════════════════════════════════');
  
  final controller = FileUploadController();
  
  // Example 1: Multiple file upload
  print('📎 Test 1: Multiple File Upload');
  print('─' * 35);
  
  final multipleFileData = {
    'title': 'Project Documents',
    'description': 'Important project files',
    'attachments': [
      UploadedFile(filename: 'doc1.pdf', size: 1024 * 1024, mimeType: 'application/pdf'),
      UploadedFile(filename: 'image1.jpg', size: 512 * 1024, mimeType: 'image/jpeg'),
    ],
    'tags': ['project', 'important', 'draft'],
  };
  
  try {
    final result = await controller.handleMultipleFileUpload(multipleFileData);
    print('Result: $result');
  } catch (e) {
    print('Error: $e');
  }
  
  print('\n' + '═' * 50 + '\n');
  
  // Example 2: Profile image upload (will fail due to large size)
  print('🖼️  Test 2: Profile Image Upload (Size Limit Test)');
  print('─' * 52);
  
  final profileImageData = {
    'attachment': UploadedFile(
      filename: 'large_avatar.png', 
      size: 3 * 1024 * 1024, // 3MB - exceeds 2MB limit
      mimeType: 'image/png',
    ),
    'alt_text': 'User avatar',
  };
  
  try {
    final result = await controller.handleProfileImageUpload(profileImageData);
    print('Result: $result');
  } catch (e) {
    print('Expected validation error occurred');
  }
  
  print('\n' + '═' * 50 + '\n');
  
  // Example 3: Complex nested validation
  print('📚 Test 3: Document Batch Upload');
  print('─' * 35);
  
  final documentBatchData = {
    'user_id': 123,
    'category': 'legal',
    'documents': [
      {
        'title': 'Contract Agreement',
        'file': UploadedFile(filename: 'contract.pdf', size: 2 * 1024 * 1024, mimeType: 'application/pdf'),
        'is_confidential': true,
        'expires_at': '2025-12-31',
      },
      {
        'title': 'Invoice',
        'file': UploadedFile(filename: 'invoice.pdf', size: 1024 * 1024, mimeType: 'application/pdf'),
        'is_confidential': false,
      },
    ],
    'metadata': {
      'project_id': 456,
      'reference_number': 'REF123ABC',
    },
  };
  
  try {
    final result = await controller.handleDocumentBatch(documentBatchData);
    print('Result: $result');
  } catch (e) {
    print('Error: $e');
  }
}

/// Mock UploadedFile class
class UploadedFile {
  final String filename;
  final int size;
  final String mimeType;
  final String? path;
  
  UploadedFile({
    required this.filename,
    required this.size,
    required this.mimeType,
    this.path,
  });
  
  @override
  String toString() => 'UploadedFile($filename, ${(size / 1024).round()}KB)';
}
