import '../lib/src/contracts/queue/queue_job.dart';
import '../lib/src/core/queue/queue.dart';
import '../lib/src/support/queue_drivers/file_queue_driver.dart';
import '../lib/src/support/queue_drivers/redis_queue_driver.dart';

/// Example jobs to demonstrate the queue system
class SendEmailJob extends QueueJob {
  final String email;
  final String subject;
  final String body;

  SendEmailJob(this.email, this.subject, this.body);

  @override
  Future<void> handle() async {
    print('📧 Sending email to: $email');
    print('   Subject: $subject');
    print('   Body: $body');
    
    // Simulate email sending
    await Future.delayed(Duration(milliseconds: 200));
    
    print('✅ Email sent successfully!');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'email': email,
      'subject': subject,
      'body': body,
    };
  }

  @override
  String get displayName => 'Send Email to $email';
}

class ProcessOrderJob extends QueueJob {
  final String orderId;
  final double amount;

  ProcessOrderJob(this.orderId, this.amount);

  @override
  Future<void> handle() async {
    print('🛒 Processing order $orderId for \$${amount.toStringAsFixed(2)}');
    
    // Simulate order processing
    await Future.delayed(Duration(milliseconds: 300));
    print('   - Payment processed');
    await Future.delayed(Duration(milliseconds: 100));
    print('   - Inventory updated');
    await Future.delayed(Duration(milliseconds: 100));
    print('   - Confirmation email queued');
    
    print('✅ Order $orderId processed successfully!');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'orderId': orderId,
      'amount': amount,
    };
  }

  @override
  String get displayName => 'Process Order $orderId';
}

class BackupDataJob extends QueueJob {
  final String database;

  BackupDataJob(this.database);

  @override
  Future<void> handle() async {
    print('💾 Starting backup of database: $database');
    
    // Simulate backup process
    await Future.delayed(Duration(milliseconds: 500));
    print('   - Creating backup snapshot...');
    await Future.delayed(Duration(milliseconds: 300));
    print('   - Compressing data...');
    await Future.delayed(Duration(milliseconds: 200));
    print('   - Uploading to cloud storage...');
    
    print('✅ Backup completed for $database');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'database': database,
    };
  }

  @override
  String get displayName => 'Backup $database Database';
}

void main() async {
  print('🚀 Advanced Queue System Example');
  print('═══════════════════════════════════');
  
  await testFileDriver();
  print('\n' + '═' * 50 + '\n');
  await testRedisDriver();
}

Future<void> testFileDriver() async {
  print('📁 Testing File Queue Driver');
  print('─────────────────────────────');
  
  // Create file driver
  final fileDriver = FileQueueDriver(queuePath: 'storage/test_queue.json');
  
  // Switch to file driver
  Queue.setDriver('file', fileDriver);
  
  print('📊 Initial stats: ${fileDriver.getStats()}');
  
  // Clear any existing jobs
  await fileDriver.clear();
  
  print('\n📤 Dispatching jobs to file queue...');
  
  // Dispatch some immediate jobs
  await Queue.dispatch(SendEmailJob('user@example.com', 'Welcome', 'Thanks for joining!'));
  await Queue.dispatch(ProcessOrderJob('order-123', 89.99));
  
  // Dispatch delayed jobs
  await Queue.dispatch(
    BackupDataJob('user_profiles'), 
    delay: Duration(seconds: 2)
  );
  await Queue.dispatch(
    SendEmailJob('admin@example.com', 'Daily Report', 'System status: OK'),
    delay: Duration(seconds: 3)
  );
  
  print('📊 After dispatching: ${fileDriver.getStats()}');
  
  print('\n⚡ Processing file queue jobs...');
  
  // Process jobs multiple times to handle delayed ones
  for (int i = 0; i < 5; i++) {
    await Queue.process();
    await Future.delayed(Duration(seconds: 1));
    
    final stats = fileDriver.getStats();
    print('📊 Round ${i + 1} stats: $stats');
    
    if (stats['total_jobs'] == 0) {
      break;
    }
  }
  
  print('✨ File queue processing completed!');
}

Future<void> testRedisDriver() async {
  print('🔴 Testing Redis Queue Driver');
  print('─────────────────────────────');
  
  try {
    // Create Redis driver
    final redisDriver = RedisQueueDriver();
    
    // Switch to Redis driver
    Queue.setDriver('redis', redisDriver);
    
    print('📊 Initial stats: ${await redisDriver.getStats()}');
    
    // Clear any existing jobs
    await redisDriver.clear();
    
    print('\n📤 Dispatching jobs to Redis queue...');
    
    // Dispatch some immediate jobs
    await Queue.dispatch(SendEmailJob('redis@example.com', 'Redis Test', 'Testing Redis queue!'));
    await Queue.dispatch(ProcessOrderJob('redis-order-456', 149.99));
    
    // Dispatch delayed jobs
    await Queue.dispatch(
      BackupDataJob('redis_cache'), 
      delay: Duration(seconds: 1)
    );
    
    print('📊 After dispatching: ${await redisDriver.getStats()}');
    
    print('\n⚡ Processing Redis queue jobs...');
    
    // Process jobs multiple times to handle delayed ones
    for (int i = 0; i < 5; i++) {
      await Queue.process();
      await Future.delayed(Duration(seconds: 1));
      
      final stats = await redisDriver.getStats();
      print('📊 Round ${i + 1} stats: $stats');
      
      if (stats['total_jobs'] == 0) {
        break;
      }
    }
    
    // Close Redis connection
    await redisDriver.close();
    
    print('✨ Redis queue processing completed!');
    
  } catch (e) {
    print('❌ Redis queue test failed (Redis server might not be running): $e');
    print('💡 To test Redis queue:');
    print('   1. Install Redis server');
    print('   2. Start Redis: redis-server');
    print('   3. Run this example again');
  }
}
