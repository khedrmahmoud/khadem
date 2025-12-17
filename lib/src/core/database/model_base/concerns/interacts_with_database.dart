import '../../../../application/khadem.dart';
import '../../../../contracts/database/query_builder_interface.dart';
import '../khadem_model.dart';
import 'has_attributes.dart';
import 'has_events.dart';

mixin InteractsWithDatabase<T> on KhademModel<T> {
  /// Get a new query builder for the model's table.
  QueryBuilderInterface<T> get query =>
      Khadem.db.table(tableName, modelFactory: (data) => newFactory(data));

  /// Save the model to the database.
  Future<bool> save() async {
    final query = this.query;

    // If the model already exists
    if (exists) {
      // Check if dirty
      if (this is HasAttributes) {
        final dirty = (this as HasAttributes).getDirty();
        if (dirty.isEmpty) return true;
      }

      if (this is HasEvents) {
        if (await (this as HasEvents).fireModelEvent('updating') == false) return false;
        if (await (this as HasEvents).fireModelEvent('saving') == false) return false;
      }

      // Perform Update
      if (this is HasAttributes) {
        final data = (this as HasAttributes).toDatabaseMap();
        // Remove ID from update data usually, but toDatabaseMap might include it.
        // We should only update dirty fields ideally.
        // Let's use getDirty() logic if available.
        
        // Re-implementing smart update logic
        final dirty = (this as HasAttributes).getDirty();
        final updateData = <String, dynamic>{};
        
        // We need to process dirty data for DB (casting)
        // This logic should probably be in HasAttributes, but we can do it here
        for(var key in dirty.keys) {
           // We need to access the raw value or cast it. 
           // HasAttributes.toDatabaseMap does it for all.
           // Let's assume we update all dirty fields.
           // We need a way to get DB-ready value for a specific key.
           // For now, let's just use toDatabaseMap() and filter by dirty keys.
           final dbMap = (this as HasAttributes).toDatabaseMap();
           if (dbMap.containsKey(key)) {
             updateData[key] = dbMap[key];
           }
        }
        
        if (updateData.isNotEmpty) {
           await query.where(primaryKey, '=', getKey()).update(updateData);
        }
      }

      if (this is HasEvents) {
        await (this as HasEvents).fireModelEvent('updated', halt: false);
        await (this as HasEvents).fireModelEvent('saved', halt: false);
      }
      
      if (this is HasAttributes) {
        (this as HasAttributes).syncOriginal();
      }
    } 
    // If the model is new
    else {
      if (this is HasEvents) {
        if (await (this as HasEvents).fireModelEvent('creating') == false) return false;
        if (await (this as HasEvents).fireModelEvent('saving') == false) return false;
      }

      // Perform Insert
      if (this is HasAttributes) {
        final data = (this as HasAttributes).toDatabaseMap();
        final id = await query.insert(data);
        
        // Set ID
        if (primaryKey == 'id') {
           // We need a way to set ID. KhademModel has id field?
           // KhademModel has int? id.
           (this as KhademModel).id = id;
           (this as HasAttributes).setAttribute('id', id);
        }
      }

      if (this is HasEvents) {
        await (this as HasEvents).fireModelEvent('created', halt: false);
        await (this as HasEvents).fireModelEvent('saved', halt: false);
      }

      if (this is HasAttributes) {
        (this as HasAttributes).syncOriginal();
      }
      
      exists = true;
    }

    return true;
  }

  /// Delete the model from the database.
  Future<bool> delete() async {
    if (!exists) return false;

    if (this is HasEvents) {
      if (await (this as HasEvents).fireModelEvent('deleting') == false) return false;
    }

    await query.where(primaryKey, '=', getKey()).delete();

    if (this is HasEvents) {
      await (this as HasEvents).fireModelEvent('deleted', halt: false);
    }

    exists = false;

    return true;
  }

  /// Reload the current model instance with fresh attributes from the database.
  Future<T> refresh() async {
    if (!exists) return this as T;

    final fresh = await query.where(primaryKey, '=', getKey()).first();

    if (fresh != null && this is HasAttributes) {
      (this as HasAttributes).fromJson((fresh as HasAttributes).attributes);
      (this as HasAttributes).syncOriginal();
    }

    return this as T;
  }

  /// Get the primary key value for a save query.
  dynamic getKey() {
    if (this is HasAttributes) {
      return (this as HasAttributes).getAttribute(primaryKey);
    }
    return (this as KhademModel).id;
  }
}
