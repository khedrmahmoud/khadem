/// Base class for custom attribute casters
/// 
/// Custom casters allow you to define how attributes are converted
/// between database representation and model properties.
/// 
/// Example:
/// ```dart
/// class UserPreferencesCaster extends AttributeCaster<UserPreferences> {
///   @override
///   UserPreferences? get(dynamic value) {
///     if (value == null) return null;
///     return UserPreferences.fromJson(jsonDecode(value));
///   }
///   
///   @override
///   dynamic set(UserPreferences? value) {
///     if (value == null) return null;
///     return jsonEncode(value.toJson());
///   }
/// }
/// ```
abstract class AttributeCaster<T> {
  /// Convert database value to model property value
  T? get(dynamic value);
  
  /// Convert model property value to database value
  dynamic set(T? value);
}
