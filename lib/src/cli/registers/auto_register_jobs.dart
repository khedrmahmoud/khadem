// import 'dart:mirrors';

// import '../../../contracts/queue_contracts/queue_job.dart';

// void autoRegisterJobs() {
//   final currentMirrorSystems = currentMirrorSystem();
//   final libraries = currentMirrorSystems.libraries;

//   for (var lib in libraries.values) {
//     for (var decl in lib.declarations.values) {
//       if (decl is ClassMirror &&
//           decl.isSubclassOf(reflectClass(QueueJob)) &&
//           !decl.isAbstract) {
//         final instance = decl.newInstance(Symbol(''), ['']) // empty constructor
//             .reflectee as QueueJob;
//         instance.register();
//       }
//     }
//   }
// }
