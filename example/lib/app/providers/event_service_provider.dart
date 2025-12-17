import 'package:khadem/khadem.dart';

import '../listeners/user_events_handler.dart';

class AppEventServiceProvider extends EventServiceProvider {
  @override
  List<Type> get subscribe => [
        UserEventsHandler,
      ];
}
