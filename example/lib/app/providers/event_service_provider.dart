import 'package:khadem/contracts.dart' show ContainerInterface;
import 'package:khadem/support.dart' show EventServiceProvider;

import '../listeners/user_events_handler.dart';

class AppEventServiceProvider extends EventServiceProvider {
  @override
  List<Type> get subscribe => [
        UserEventsHandler,
      ];

  @override
  void register(ContainerInterface container) {
    container.lazySingleton<UserEventsHandler>((c) => UserEventsHandler());
  }
}
