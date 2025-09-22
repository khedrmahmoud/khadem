// import 'dart:async';
// import 'package:cron_parser/cron_parser.dart';

// typedef ScheduledCallback = Future<void> Function();

// class ScheduledTask {
//   final String name;
//   final Duration? interval;
//   final String? cron;
//   final ScheduledCallback callback;
//   final bool once;
//   final bool enabled;
//   final bool retryOnFail;

//   Timer? _timer;
//   DateTime? _lastRun;

//   ScheduledTask({
//     required this.name,
//     this.interval,
//     this.cron,
//     required this.callback,
//     this.once = false,
//     this.enabled = true,
//     this.retryOnFail = false,
//   }) {
//     if (interval == null && cron == null) {
//       throw ArgumentError('Either interval or cron must be provided.');
//     }
//   }

//   void start() {
//     if (!enabled) return;

//     if (interval != null) {
//       _timer = Timer.periodic(interval!, (_) => _run());
//     } else if (cron != null) {
//       _scheduleNextCronRun();
//     } else {
//       throw Exception("No valid schedule provided for task [$name]");
//     }
//   }

//   void _scheduleNextCronRun() {
//     final next = Cron().parse(cron!, DateTime.now());
//     final delay = next.next().difference(DateTime.now());

//     _timer = Timer(delay, () async {
//       await _run();
//       if (!once) _scheduleNextCronRun();
//     });
//   }

//   Future<void> _run() async {
//     try {
//       _lastRun = DateTime.now();
//       await callback();
//       if (once) stop();
//     } catch (e, s) {
//       print('❌ Error in [$name]: $e\n$s');
//       if (retryOnFail) {
//         print('🔁 Retrying task [$name] in 5 seconds...');
//         Timer(Duration(seconds: 5), _run);
//       }
//     }
//   }

//   void stop() {
//     _timer?.cancel();
//   }

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'lastRun': _lastRun?.toIso8601String(),
//         'enabled': enabled,
//         'once': once,
//         'interval': interval?.inSeconds,
//         'cron': cron,
//       };
// }

// class BackgroundScheduler {
//   final Map<String, ScheduledTask> _tasks = {};

//   void schedule(ScheduledTask task) {
//     if (_tasks.containsKey(task.name)) {
//       throw Exception('Task with name ${task.name} already exists.');
//     }
//     _tasks[task.name] = task;
//     task.start();
//   }

//   void stop(String name) {
//     _tasks[name]?.stop();
//   }

//   void stopAll() {
//     for (final task in _tasks.values) {
//       task.stop();
//     }
//   }

//   List<Map<String, dynamic>> status() {
//     return _tasks.values.map((t) => t.toJson()).toList();
//   }

//   bool isRunning(String name) => _tasks[name]?._timer?.isActive ?? false;
// }
