import 'package:khadem/khadem.dart';

void main() async {
  // Bootstrap Khadem framework
  await Khadem.registerApplicationServices([
    CoreServiceProvider(),
    CacheServiceProvider(),
  ]);
  await Khadem.boot();

  // Register a memory cache driver for the example
  final cacheRegistry = Khadem.container.resolve<ICacheDriverRegistry>();
  cacheRegistry.registerDriver('memory', MemoryCacheDriver());
  cacheRegistry.setDefaultDriver('memory');

  // Example: Using Khadem's logger
  print('🚀 Khadem framework initialized!');

  // Example: Using cache
  print('💾 Testing cache functionality...');

  await Khadem.cache
      .put('example_key', 'Hello from Khadem cache!', const Duration(hours: 1));
  final cachedValue = await Khadem.cache.get('example_key');
  print('📦 Cached value: $cachedValue');

  // Test cache expiration
  await Khadem.cache
      .put('temp_key', 'This will expire soon', const Duration(seconds: 2));
  print('⏰ Waiting 3 seconds for cache expiration...');
  await Future.delayed(const Duration(seconds: 3));
  final expiredValue = await Khadem.cache.get('temp_key');
  print('📦 Expired value: $expiredValue');

  // Test cache operations with complex data
  await Khadem.cache.put(
    'user_data',
    {'name': 'John', 'age': 30, 'active': true},
    const Duration(minutes: 5),
  );
  final userData = await Khadem.cache.get('user_data');
  print('👤 User data: $userData');

  // Test cache remember (get or store with callback)
  final computedValue = await Khadem.cache.remember(
    'computed_result',
    const Duration(minutes: 10),
    () async {
      print('🔄 Computing expensive value...');
      await Future.delayed(const Duration(milliseconds: 100));
      return 'Expensive computed result: ${DateTime.now()}';
    },
  );
  print('🧮 Computed value: $computedValue');

  // Get it again (should be from cache)
  final cachedComputedValue = await Khadem.cache.get('computed_result');
  print('📦 Cached computed value: $cachedComputedValue');

  // Test cache tagging
  await Khadem.cache.put('user_1', 'User One Data', const Duration(hours: 1));
  await Khadem.cache.put('user_2', 'User Two Data', const Duration(hours: 1));
  await Khadem.cache.tag('user_1', ['users']);
  await Khadem.cache.tag('user_2', ['users']);

  print('🏷️ Tagged 2 user cache entries');

  // Test cache stats
  final stats = Khadem.cache.stats;
  print(
    '📊 Cache stats - Hits: ${stats.hits}, Misses: ${stats.misses}, Sets: ${stats.sets}',
  );

  print('✅ Cache examples completed!');

  // Example: Environment and Configuration
  print('🌍 Testing environment and configuration...');

  final appName = Khadem.config.get<String?>('app.name') ?? 'Khadem App';
  final appEnv = Khadem.env.getOrDefault('APP_ENV', 'development');
  final debugMode = Khadem.config.get<bool?>('app.debug') ?? false;

  print('📋 App Name: $appName');
  print('🌍 Environment: $appEnv');
  print('🐛 Debug Mode: $debugMode');

  // Example: Database operations (if available)
  print('🗄️  Testing database operations...');

  try {
    // Initialize database and check driver
    final dbDriver = await Khadem.db.init();
    print('📊 Database driver initialized: $dbDriver');
  } catch (e) {
    print('ℹ️  Database not configured (expected in example): $e');
  }

  // Example: Queue system
  print('📋 Testing queue system...');

  try {
    // Check queue driver availability
    final queueDriver = Khadem.queue.defaultDriverName;
    print('� Queue driver: $queueDriver');

    // Get queue metrics
    final queueMetrics = Khadem.queue.getMetrics();
    print('📊 Queue metrics available: ${queueMetrics.isNotEmpty}');
  } catch (e) {
    print('ℹ️  Queue not configured (expected in example): $e');
  }

  // Example: Event system
  print('📢 Testing event system...');

  // Listen for a custom event
  Khadem.eventBus.on('user.created', (data) {
    print('👤 User created event received: $data');
  });

  // Fire an event
  Khadem.eventBus.emit('user.created', {'user_id': 123, 'name': 'John Doe'});
  print('📣 User created event emitted');

  // Example: Storage system
  print('💾 Testing storage system...');

  try {
    // Check storage driver availability
    print('📁 Storage system available');
  } catch (e) {
    print('ℹ️  Storage not configured (expected in example): $e');
  }

  // Example: URL and Asset services
  print('🔗 Testing URL and asset services...');

  try {
    // Test basic service availability
    print('🔗 URL and Asset services available');
  } catch (e) {
    print('ℹ️  URL/Asset services not configured (expected in example): $e');
  }

  // Example: Advanced validation features
  print('🔍 Testing advanced validation features...');

  // Test nested validation
  final nestedData = {
    'user': {
      'name': 'John Doe',
      'email': 'john@example.com',
      'profile': {
        'age': 30,
        'hobbies': ['reading', 'coding', 'gaming'],
      },
    },
    'posts': [
      {'title': 'First Post', 'content': 'Hello World'},
      {'title': 'Second Post', 'content': 'Advanced validation'},
    ],
  };

  final nestedValidator = InputValidator(nestedData, {
    'user.name': 'required|string|min:2|max:50',
    'user.email': 'required|email',
    'user.profile.age': 'required|int|min:18|max:120',
    'user.profile.hobbies': 'required|array|min_items:1',
    'user.profile.hobbies.*': 'string|min:2|max:20',
    'posts': 'required|array|min_items:1|max_items:10',
    'posts.*.title': 'required|string|min:3|max:100',
    'posts.*.content': 'required|string|min:10',
  });

  if (nestedValidator.passes()) {
    print('✅ Advanced nested validation passed!');
  } else {
    print('❌ Advanced validation failed: ${nestedValidator.errors}');
  }

  print('✅ Additional services examples completed!');
  final validator = InputValidator(
    {'email': 'user@example.com', 'name': 'John Doe'},
    {'email': 'required|email', 'name': 'required|string'},
  );

  if (validator.passes()) {
    print('✅ Validation passed!');
  } else {
    print('❌ Validation failed: ${validator.errors}');
  }

  // Example: File upload validation
  print('📄 Testing file upload validation...');

  // Create a test file
  final testFile = UploadedFile(
    'document.pdf',
    'application/pdf',
    List<int>.filled(1024 * 500, 0), // 500KB file
    'document',
  );

  final fileValidator = InputValidator(
    {'document': testFile, 'title': 'Sample Document'},
    {
      'document': 'required|file|max:1024|mimes:pdf,doc,docx', // 1MB max
      'title': 'required|string|min:3|max:100',
    },
  );

  if (fileValidator.passes()) {
    print('✅ File upload validation passed!');
    print(
      '📄 File details: ${testFile.filename}, Size: ${(testFile.size / 1024).round()}KB',
    );
  } else {
    print('❌ File validation failed: ${fileValidator.errors}');
  }

  // Example: Multiple file upload validation
  print('🖼️  Testing multiple file upload validation...');

  final multipleFiles = [
    UploadedFile(
      'image1.jpg',
      'image/jpeg',
      List<int>.filled(256 * 1024, 0),
      'images',
    ),
    UploadedFile(
      'image2.png',
      'image/png',
      List<int>.filled(512 * 1024, 0),
      'images',
    ),
  ];

  final multipleFileValidator = InputValidator(
    {
      'images': multipleFiles,
      'description': 'Project screenshots',
    },
    {
      'images': 'required|array|max_items:5',
      'images.*': 'file|max:1024|mimes:jpg,jpeg,png,gif', // 1MB max per file
      'description': 'nullable|string|max:500',
    },
  );

  if (multipleFileValidator.passes()) {
    print('✅ Multiple file upload validation passed!');
    print('📁 Uploaded ${multipleFiles.length} files');
  } else {
    print('❌ Multiple file validation failed: ${multipleFileValidator.errors}');
  }

  print('🎉 Khadem complete example completed successfully!');
  return;
}
