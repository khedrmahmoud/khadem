import '../../../../application/khadem.dart';
import '../../../../contracts/database/query_builder_interface.dart';
import '../../orm/model_lifecycle.dart';
import 'has_attributes.dart';
import 'has_events.dart';

mixin InteractsWithDatabase<T> {
  // Abstract requirements
  String get table;
  String get tableName;
  String get primaryKey;
  int? get id;
  set id(int? value);
  bool exists = false;

  T newFactory(Map<String, dynamic> data);

  // Helper to get key value
  dynamic getKey() {
    if (this is HasAttributes) {
      return (this as HasAttributes).getAttribute(primaryKey);
    }
    return id;
  }

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
        if (await (this as HasEvents).fireModelEvent(ModelLifecycle.updating) ==
            false) {
          return false;
        }
        if (await (this as HasEvents).fireModelEvent(ModelLifecycle.saving) ==
            false) {
          return false;
        }
      }

      // Perform Update
      if (this is HasAttributes) {
        final dirty = (this as HasAttributes).getDirty();
        final updateData = <String, dynamic>{};

        final dbMap = (this as HasAttributes).toDatabaseMap();
        for (var key in dirty.keys) {
          if (dbMap.containsKey(key)) {
            updateData[key] = dbMap[key];
          }
        }

        if (updateData.isNotEmpty) {
          await query.where(primaryKey, '=', getKey()).update(updateData);
        }
      }

      if (this is HasEvents) {
        await (this as HasEvents)
            .fireModelEvent(ModelLifecycle.updated, halt: false);
        await (this as HasEvents)
            .fireModelEvent(ModelLifecycle.saved, halt: false);
      }

      if (this is HasAttributes) {
        (this as HasAttributes).syncOriginal();
      }
    }
    // If the model is new
    else {
      if (this is HasEvents) {
        if (await (this as HasEvents).fireModelEvent(ModelLifecycle.creating) ==
            false) {
          return false;
        }
        if (await (this as HasEvents).fireModelEvent(ModelLifecycle.saving) ==
            false) {
          return false;
        }
      }

      // Perform Insert
      if (this is HasAttributes) {
        final data = (this as HasAttributes).toDatabaseMap();
        final insertId = await query.insert(data);

        // Set ID
        if (primaryKey == 'id') {
          this.id = insertId;
          (this as HasAttributes).setAttribute('id', insertId);
        }
      }

      if (this is HasEvents) {
        await (this as HasEvents)
            .fireModelEvent(ModelLifecycle.created, halt: false);
        await (this as HasEvents)
            .fireModelEvent(ModelLifecycle.saved, halt: false);
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
      if (await (this as HasEvents).fireModelEvent(ModelLifecycle.deleting) ==
          false) {
        return false;
      }
    }

    await query.where(primaryKey, '=', getKey()).delete();

    if (this is HasEvents) {
      await (this as HasEvents)
          .fireModelEvent(ModelLifecycle.deleted, halt: false);
    }

    exists = false;
    return true;
  }

  /// Refresh the model from the database.
  Future<void> refresh() async {
    if (!exists) return;

    final fresh = await query.where(primaryKey, '=', getKey()).first();
    if (fresh != null) {
      if (this is HasAttributes) {
        if (fresh is HasAttributes) {
          (this as HasAttributes).fromJson((fresh as HasAttributes).attributes);
        }
      }
    }
  }

  /// Get a fresh instance of the model from the database.
  Future<T?> fresh([List<String> withRelations = const []]) async {
    if (!exists) return null;

    var q = query.where(primaryKey, '=', getKey());
    if (withRelations.isNotEmpty) {
      q = q.withRelations(withRelations);
    }

    return q.first();
  }

  /// Update the model in the database.
  Future<bool> update(Map<String, dynamic> attributes) async {
    if (!exists) return false;

    if (this is HasAttributes) {
      (this as HasAttributes).fill(attributes);
    }

    return save();
  }

  /// Find a model by its primary key.
  Future<T?> find(dynamic id) async {
    return query.where(primaryKey, '=', id).first();
  }

  /// Find a model by its primary key or throw an exception.
  Future<T> findOrFail(dynamic id) async {
    final result = await find(id);
    if (result == null) {
      throw Exception('Model not found');
    }
    return result;
  }

  /// Get all models.
  Future<List<T>> all() async {
    return query.get();
  }

  /// Increment a column's value.
  Future<void> increment(String column, [int amount = 1]) async {
    if (!exists) return;

    await query.where(primaryKey, '=', getKey()).increment(column, amount);

    if (this is HasAttributes) {
      final current = (this as HasAttributes).getAttribute(column);
      if (current is num) {
        (this as HasAttributes).setAttribute(column, current + amount);
        (this as HasAttributes).syncOriginal();
      }
    }
  }

  /// Decrement a column's value.
  Future<void> decrement(String column, [int amount = 1]) async {
    if (!exists) return;

    await query.where(primaryKey, '=', getKey()).decrement(column, amount);

    if (this is HasAttributes) {
      final current = (this as HasAttributes).getAttribute(column);
      if (current is num) {
        (this as HasAttributes).setAttribute(column, current - amount);
        (this as HasAttributes).syncOriginal();
      }
    }
  }
}
