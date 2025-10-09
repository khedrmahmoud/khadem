import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'attribute_caster.dart';

/// Cast attribute to/from JSON (Map<String, dynamic>)
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'settings': JsonCast,
///   'metadata': JsonCast,
/// };
/// 
/// // Usage:
/// user.settings = {'theme': 'dark', 'lang': 'en'};
/// print(user.settings['theme']); // 'dark'
/// ```
class JsonCast extends AttributeCaster<Map<String, dynamic>> {
  @override
  Map<String, dynamic>? get(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  dynamic set(Map<String, dynamic>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }
}

/// Cast attribute to/from Array (List<String>)
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'roles': ArrayCast,
///   'tags': ArrayCast,
/// };
/// 
/// // Usage:
/// user.roles = ['admin', 'editor'];
/// print(user.roles.first); // 'admin'
/// ```
class ArrayCast extends AttributeCaster<List<String>> {
  @override
  List<String>? get(dynamic value) {
    if (value == null) return null;
    if (value is List<String>) return value;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  dynamic set(List<String>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }
}

/// Cast attribute to/from JSON Array (List<Map<String, dynamic>>)
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'addresses': JsonArrayCast,
///   'items': JsonArrayCast,
/// };
/// 
/// // Usage:
/// user.addresses = [
///   {'street': '123 Main', 'city': 'NYC'},
///   {'street': '456 Oak', 'city': 'LA'},
/// ];
/// print(user.addresses[0]['city']); // 'NYC'
/// ```
class JsonArrayCast extends AttributeCaster<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>>? get(dynamic value) {
    if (value == null) return null;
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value.map((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList();
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  dynamic set(List<Map<String, dynamic>>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }
}

/// Cast attribute to/from encrypted values
/// 
/// Uses SHA-256 hashing for one-way encryption (good for passwords).
/// For two-way encryption, extend this class and implement your own logic.
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'password': EncryptedCast,
///   'api_key': EncryptedCast,
/// };
/// 
/// // Usage:
/// user.password = 'secret123'; // Auto-hashed on set
/// // Cannot retrieve original password (one-way hash)
/// ```
class EncryptedCast extends AttributeCaster<String> {
  @override
  String? get(dynamic value) {
    // For one-way encryption (hashing), we return the hash
    // Override this for two-way encryption
    if (value == null) return null;
    return value.toString();
  }

  @override
  dynamic set(String? value) {
    if (value == null) return null;
    
    // Hash the value using SHA-256
    final bytes = utf8.encode(value);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

/// Cast attribute to/from integer
/// 
/// Handles string to int conversion automatically
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'age': IntCast,
///   'count': IntCast,
/// };
/// ```
class IntCast extends AttributeCaster<int> {
  @override
  int? get(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  @override
  dynamic set(int? value) => value;
}

/// Cast attribute to/from double
/// 
/// Handles string to double conversion automatically
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'price': DoubleCast,
///   'rating': DoubleCast,
/// };
/// ```
class DoubleCast extends AttributeCaster<double> {
  @override
  double? get(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    if (value is int) return value.toDouble();
    return null;
  }

  @override
  dynamic set(double? value) => value;
}

/// Cast attribute to/from boolean
/// 
/// Handles string and int to bool conversion automatically
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'is_active': BoolCast,
///   'verified': BoolCast,
/// };
/// ```
class BoolCast extends AttributeCaster<bool> {
  @override
  bool? get(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  @override
  dynamic set(bool? value) => value;
}

/// Cast attribute to/from DateTime
/// 
/// Handles string to DateTime conversion automatically
/// 
/// Example:
/// ```dart
/// Map<String, Type> get casts => {
///   'birth_date': DateTimeCast,
///   'published_at': DateTimeCast,
/// };
/// ```
class DateTimeCast extends AttributeCaster<DateTime> {
  @override
  DateTime? get(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  dynamic set(DateTime? value) => value;
}
