import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/registry/index.dart';
import 'package:khadem/src/core/queue/serialization/index.dart';

/// Example: Send email job with serialization support
///
/// This shows the complete pattern for creating jobs that work
/// with persistent queue drivers (file, Redis, database).
class SendEmailJob extends QueueJob with SerializableJob {
  final String email;
  final String subject;
  final String body;

  SendEmailJob(this.email, this.subject, this.body);

  /// Factory constructor for deserialization
  /// This is called by QueueJobRegistry when reconstructing jobs from storage
  factory SendEmailJob.fromJson(Map<String, dynamic> json) {
    return SendEmailJob(
      json['email'] as String,
      json['subject'] as String,
      json['body'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'email': email,
        'subject': subject,
        'body': body,
      };

  @override
  Future<void> handle() async {
    print('📧 Sending email to $email');
    print('   Subject: $subject');

    // Simulate email sending
    await Future.delayed(const Duration(seconds: 1));

    print('✅ Email sent successfully to $email');
  }

  @override
  String get displayName => 'Send Email to $email';

  @override
  int get maxRetries => 3;
}

/// Example: Process payment job
class ProcessPaymentJob extends QueueJob with SerializableJob {
  final String orderId;
  final double amount;
  final String currency;

  ProcessPaymentJob(this.orderId, this.amount, this.currency);

  factory ProcessPaymentJob.fromJson(Map<String, dynamic> json) {
    return ProcessPaymentJob(
      json['orderId'] as String,
      json['amount'] as double,
      json['currency'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      };

  @override
  Future<void> handle() async {
    print('💳 Processing payment for order $orderId');
    print('   Amount: $amount $currency');

    // Simulate payment processing
    await Future.delayed(const Duration(milliseconds: 500));

    print('✅ Payment processed successfully for order $orderId');
  }

  @override
  String get displayName => 'Process Payment - Order $orderId';

  @override
  int get maxRetries => 5; // Payments should retry more

  @override
  Duration get retryDelay => const Duration(minutes: 1);
}

/// Example: Generate report job with complex data
class GenerateReportJob extends QueueJob with SerializableJob {
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> includeColumns;

  GenerateReportJob(
    this.reportType,
    this.startDate,
    this.endDate,
    this.includeColumns,
  );

  factory GenerateReportJob.fromJson(Map<String, dynamic> json) {
    return GenerateReportJob(
      json['reportType'] as String,
      DateTime.parse(json['startDate'] as String),
      DateTime.parse(json['endDate'] as String),
      (json['includeColumns'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'reportType': reportType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'includeColumns': includeColumns,
      };

  @override
  Future<void> handle() async {
    print('📊 Generating $reportType report');
    print('   Period: ${startDate.toLocal()} to ${endDate.toLocal()}');
    print('   Columns: ${includeColumns.join(', ')}');

    // Simulate report generation
    await Future.delayed(const Duration(seconds: 2));

    print('✅ Report generated successfully');
  }

  @override
  String get displayName => 'Generate $reportType Report';

  @override
  int get maxRetries => 2;

  @override
  Duration? get timeout => const Duration(minutes: 10);
}

/// Register all job types at application startup
///
/// Call this function in your application's main() or bootstrap process
/// BEFORE dispatching any jobs to persistent queues.
void registerQueueJobs() {
  QueueJobRegistry.registerAll({
    'SendEmailJob': (json) => SendEmailJob.fromJson(json),
    'ProcessPaymentJob': (json) => ProcessPaymentJob.fromJson(json),
    'GenerateReportJob': (json) => GenerateReportJob.fromJson(json),
  });
}
