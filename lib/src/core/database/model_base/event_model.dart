import '../../../application/khadem.dart';
import '../orm/model_events.dart';
import 'khadem_model.dart';

class EventModel<T> {
  final KhademModel<T> model;

  EventModel(this.model);

  Future<void> fireEvent(String Function(String) eventBuilder) async {
    await Khadem.eventBus
        .emit(eventBuilder(model.modelName.toLowerCase()), model);
  }

  Future<void> beforeCreate() => fireEvent(ModelEvents.creating);
  Future<void> afterCreate() => fireEvent(ModelEvents.created);
  Future<void> beforeUpdate() => fireEvent(ModelEvents.updating);
  Future<void> afterUpdate() => fireEvent(ModelEvents.updated);
  Future<void> beforeDelete() => fireEvent(ModelEvents.deleting);
  Future<void> afterDelete() => fireEvent(ModelEvents.deleted);
}
