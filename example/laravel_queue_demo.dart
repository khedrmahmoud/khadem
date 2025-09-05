import 'package:khadem/khadem_dart.dart';
import 'package:khadem/src/core/queue/queue.dart' as LaravelQueue;

/// Example jobs for testing
class WelcomeEmailJob extends QueueJob {
  final String email;
  final String name;

  WelcomeEmailJob(this.email, this.name);

  @override
  Future<void> handle() async {
    print('📧 Sending welcome email to $name ($email)');
    await Future.delayed(Duration(milliseconds: 100));
    print('✅ Welcome email sent!');
  }

  @override
  String get displayName => 'Welcome Email to $name';
}

class ProcessPaymentJob extends QueueJob {
  final String orderId;
  final double amount;
  final String currency;

  ProcessPaymentJob(this.orderId, this.amount, this.currency);

  @override
  Future<void> handle() async {
    print('💳 Processing payment for order $orderId: $amount $currency');
    
    // Simulate payment processing
    await Future.delayed(Duration(milliseconds: 300));
    
    if (amount > 1000) {
      print('   🔍 High-value transaction - additional verification');
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    print('✅ Payment processed successfully!');
  }

  @override
  String get displayName => 'Process Payment $orderId';

  @override
  int get maxRetries => 5; // Payment jobs should retry more

  @override
  Duration get retryDelay => Duration(minutes: 2); // Longer retry delay
}

class SendNotificationJob extends QueueJob {
  final List<String> userIds;
  final String message;
  final String type;

  SendNotificationJob(this.userIds, this.message, this.type);

  @override
  Future<void> handle() async {
    print('🔔 Sending $type notification to ${userIds.length} users');
    print('   Message: $message');
    
    for (final userId in userIds) {
      await Future.delayed(Duration(milliseconds: 50));
      print('   ✓ Sent to user $userId');
    }
    
    print('✅ All notifications sent!');
  }

  @override
  String get displayName => 'Send $type Notification';

  @override
  String get queue => 'notifications'; // Use specific queue
}

void main() async {
  print('🚀 Laravel-Style Queue System Demo');
  print('══════════════════════════════════════');

  // Initialize Khadem framework
  await Khadem.registerCoreServices();
  await Khadem.boot();

  await demoDirectQueueUsage();
  await demoKhademFacadeUsage();
}

Future<void> demoDirectQueueUsage() async {
  print('\n📋 Demo 1: Direct Queue Usage (like Laravel)');
  print('─────────────────────────────────────────────');

  // Import the Queue class
  // Use memory driver for this demo
  LaravelQueue.Queue.useDriver('memory');
  LaravelQueue.Queue.clear();

  // Dispatch individual jobs
  print('\n📤 Dispatching jobs directly...');
  
  await LaravelQueue.Queue.dispatch(WelcomeEmailJob('john@example.com', 'John Doe'));
  await LaravelQueue.Queue.dispatch(ProcessPaymentJob('order-123', 250.00, 'USD'));
  
  // Dispatch with delay
  await LaravelQueue.Queue.dispatch(
    SendNotificationJob(['user1', 'user2', 'user3'], 'Welcome to our platform!', 'welcome'),
    delay: Duration(seconds: 1)
  );

  // Batch dispatch
  await LaravelQueue.Queue.dispatchBatch([
    WelcomeEmailJob('jane@example.com', 'Jane Smith'),
    ProcessPaymentJob('order-456', 1500.00, 'EUR'),
    WelcomeEmailJob('bob@example.com', 'Bob Johnson'),
  ]);

  print('\n📊 Queue Status: ${LaravelQueue.Queue.stats()}');

  // Process all jobs
  print('\n⚡ Processing all jobs...');
  for (int i = 0; i < 20; i++) {
    await LaravelQueue.Queue.work();
    await Future.delayed(Duration(milliseconds: 100));
    
    final stats = LaravelQueue.Queue.stats();
    if (stats['pending_jobs'] == 0) break;
  }

  print('\n📊 Final Status: ${LaravelQueue.Queue.stats()}');
}

Future<void> demoKhademFacadeUsage() async {
  print('\n🏗️ Demo 2: Using Khadem Facade (Laravel-style)');
  print('───────────────────────────────────────────────');

  // The Khadem facade provides Laravel-style methods
  print('\n📤 Using Khadem.dispatch()...');
  
  // Single job dispatch
  await Khadem.dispatch(WelcomeEmailJob('admin@example.com', 'Admin User'));
  
  // Batch dispatch through facade
  await Khadem.dispatchBatch([
    ProcessPaymentJob('order-789', 99.99, 'USD'),
    SendNotificationJob(['admin'], 'System maintenance scheduled', 'system'),
    WelcomeEmailJob('support@example.com', 'Support Team'),
  ]);

  print('\n✨ Jobs dispatched through Khadem facade!');
}
