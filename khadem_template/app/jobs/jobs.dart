import 'package:khadem/khadem_dart.dart' show QueueJob;

import 'send_user_notification_job.dart';

// Job registry - automatically maintained by the job generator
// This file is used by the 'khadem queue:work' command to discover and register jobs
List<QueueJob Function()> jobFactories = <QueueJob Function()>[
  // User notification jobs
  () => SendUserNotificationJob(''),

  // Add new jobs here as you create them
  // Example: () => ProcessPaymentJob(),
  // Example: () => SendWelcomeEmailJob(),
];

// Job registry map for quick lookup by class name
Map<String, QueueJob Function()> jobRegistry = {
  'SendUserNotificationJob': () => SendUserNotificationJob(''),
  // Add new jobs here as you create them
};

// Note: This file is automatically updated when you run:
// khadem make:job create_something_job
//
// The queue:work command will:
// 1. Load this registry file using Dart mirrors
// 2. Instantiate job classes dynamically
// 3. Register them with the queue system
// 4. Process jobs automatically