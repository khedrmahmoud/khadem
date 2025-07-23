import 'khadem_model.dart';

class DatabaseModel<T> {
  final KhademModel<T> model;

  DatabaseModel(this.model);

  Future<void> save() async {
    if (model.id != null) {
      await model.event.beforeUpdate();
      await model.query
          .where('id', '=', model.id)
          .update(model.toDatabaseJson());
      await model.event.afterUpdate();
    } else {
      await model.event.beforeCreate();
      final id = await model.query.insert(model.toDatabaseJson());
      model.id = id;
      await model.event.afterCreate();
    }
  }

  Future<void> delete() async {
    await model.event.beforeDelete();
    await model.query.where('id', '=', model.id).delete();
    await model.event.afterDelete();
  }
}
