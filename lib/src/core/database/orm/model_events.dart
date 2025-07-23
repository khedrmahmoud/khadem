/// Event names used by Eloquent-like models.
class ModelEvents {
  static String creating(String model) => '$model.creating';
  static String created(String model) => '$model.created';

  static String updating(String model) => '$model.updating';
  static String updated(String model) => '$model.updated';

  static String deleting(String model) => '$model.deleting';
  static String deleted(String model) => '$model.deleted';

  static String restoring(String model) => '$model.restoring';
  static String restored(String model) => '$model.restored';
}
