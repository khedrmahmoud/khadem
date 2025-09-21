// import 'dart:mirrors';

// /// Utility class for inspecting model metadata using reflection.
// class ModelReflector {
//   /// Returns a map of field names and their types.
//   static Map<String, Type> getFieldTypes(Type type) {
//     final mirror = reflectClass(type);
//     final fields = <String, Type>{};

//     for (final decl in mirror.declarations.values) {
//       if (decl is VariableMirror && !decl.isStatic) {
//         fields[MirrorSystem.getName(decl.simpleName)] = decl.type.reflectedType;
//       }
//     }

//     return fields;
//   }

//   /// Gets the table name if defined as static `tableName`.
//   static String? getTableName(Type type) {
//     final mirror = reflectClass(type);
//     final tableNameField = mirror.staticMembers.keys.firstWhere(
//       (key) => MirrorSystem.getName(key) == 'tableName',
//       orElse: () => Symbol(''),
//     );

//     if (tableNameField != Symbol('')) {
//       return mirror.getField(tableNameField).reflectee as String?;
//     }
//     return null;
//   }
// }
