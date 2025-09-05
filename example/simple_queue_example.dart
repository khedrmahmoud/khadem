import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/queue.dart';

/// Simple email job - Laravel style, no registration needed!
class SendEmailJob extends QueueJob {
  final String to;
  final String subject;
  final String body;

  SendEmailJob(this.to, this.subject, this.body);

  @override
  Future<void> handle() async {
    print('📧 Sending email to: $to');
    print('   Subject: $subject');
    print('   Body: $body');
    
    // Simulate email sending
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('✅ Email sent successfully!');
  }

  @override
  String get displayName => 'Send Email to $to';

  @override
  int get maxRetries => 5; // Custom retry count
}

/// Simple notification job
class SendNotificationJob extends QueueJob {
  final String userId;
  final String message;

  SendNotificationJob(this.userId, this.message);

  @override
  Future<void> handle() async {
    print('🔔 Sending notification to user $userId: $message');
    await Future.delayed(Duration(milliseconds: 50));
    print('✅ Notification sent!');
  }

  @override
  String get displayName => 'Notify User $userId';
}

/// Process order job with custom settings
class ProcessOrderJob extends QueueJob {
  final String orderId;
  final double amount;

  ProcessOrderJob(this.orderId, this.amount);

  @override
  Future<void> handle() async {
    print('🛒 Processing order $orderId for \$$amount');
    
    // Simulate processing steps
    await Future.delayed(Duration(milliseconds: 200));
    print('   - Payment processed');
    
    await Future.delayed(Duration(milliseconds: 100));
    print('   - Inventory updated');
    
    await Future.delayed(Duration(milliseconds: 100));
    print('   - Confirmation email queued');
    
    print('✅ Order $orderId processed successfully!');
  }

  @override
  String get displayName => 'Process Order $orderId';

  @override
  Duration? get timeout => Duration(minutes: 5); // Custom timeout

  @override
  String get queue => 'orders'; // Custom queue
}

void main() async {
  print('🚀 Laravel-Style Queue Example');
  print('═══════════════════════════════');

  // Test different drivers
  await testSyncDriver();
  await testMemoryDriver();
}

Future<void> testSyncDriver() async {
  print('\n📤 Testing Sync Driver (immediate execution)');
  print('─────────────────────────────────────────────');
  
  // Use sync driver (default)
  Queue.useDriver('sync');
  
  // Jobs execute immediately
  await Queue.dispatch(SendEmailJob('user@example.com', 'Welcome!', 'Welcome to our service!'));
  await Queue.dispatch(SendNotificationJob('user123', 'You have a new message!'));
  await Queue.dispatch(ProcessOrderJob('order-456', 99.99));
}

Future<void> testMemoryDriver() async {
  print('\n💾 Testing Memory Driver (queued execution)');
  print('────────────────────────────────────────────');
  
  // Use memory driver
  Queue.useDriver('memory');
  
  // Clear any existing jobs
  Queue.clear();
  
  // Dispatch jobs (they get queued)
  print('\n📥 Dispatching jobs to queue...');
  await Queue.dispatch(SendEmailJob('admin@example.com', 'Daily Report', 'Here is your report...'));
  await Queue.dispatch(SendNotificationJob('user456', 'Your order shipped!'));
  
  // Dispatch with delay
  await Queue.dispatch(
    ProcessOrderJob('order-789', 149.99), 
    delay: Duration(seconds: 2)
  );
  
  // Batch dispatch
  await Queue.dispatchBatch([
    SendEmailJob('user1@example.com', 'Newsletter', 'Latest news...'),
    SendEmailJob('user2@example.com', 'Newsletter', 'Latest news...'),
    SendNotificationJob('user789', 'Special offer!'),
  ]);
  
  print('\n📊 Queue stats: ${Queue.stats()}');
  
  // Process all jobs
  print('\n⚡ Processing queued jobs...');
  for (int i = 0; i < 10; i++) {
    await Queue.work();
    await Future.delayed(Duration(milliseconds: 100));
    
    final stats = Queue.stats();
    if (stats['pending_jobs'] == 0) {
      break;
    }
  }
  
  print('\n📊 Final stats: ${Queue.stats()}');
  print('\n✨ Done! Laravel-style queue system working perfectly!');
}
