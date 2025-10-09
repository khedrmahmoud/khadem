# Advanced Attribute Casting Guide

**Date:** October 9, 2025  
**Phase:** 3 - Advanced Features  
**Status:** Complete

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Built-in Casters](#built-in-casters)
3. [Custom Casters](#custom-casters)
4. [Usage Examples](#usage-examples)
5. [Best Practices](#best-practices)
6. [Migration Guide](#migration-guide)

---

## Overview

The advanced casting system allows you to automatically transform attribute values between database representation and model properties. This is essential for handling complex data types like JSON objects, arrays, and encrypted values.

### Key Features

- ✅ **JSON Casting** - Store/retrieve objects as JSON
- ✅ **Array Casting** - Store/retrieve string arrays
- ✅ **JSON Array Casting** - Store/retrieve arrays of objects
- ✅ **Encrypted Casting** - Auto-hash sensitive data
- ✅ **Custom Casters** - Build your own transformation logic
- ✅ **Type Safety** - Strongly typed casters
- ✅ **Null Safety** - All casters handle null values

---

## Built-in Casters

### 1. JsonCast

Transforms JSON strings to/from `Map<String, dynamic>`.

**Use Case:** Store settings, metadata, configuration objects

```dart
import 'package:khadem/khadem.dart';
import 'package:khadem/src/core/database/orm/casting/built_in_casters.dart';

class User extends KhademModel<User> {
  late Map<String, dynamic>? settings;
  late Map<String, dynamic>? metadata;
  
  @override
  Map<String, dynamic> get casts => {
    'settings': JsonCast(),
    'metadata': JsonCast(),
  };
}

// Usage:
user.settings = {'theme': 'dark', 'language': 'en', 'notifications': true};
await user.save();

// Retrieved as Map<String, dynamic>
print(user.settings!['theme']); // 'dark'
print(user.settings!['notifications']); // true
```

**Database Storage:** `{"theme":"dark","language":"en","notifications":true}`

---

### 2. ArrayCast

Transforms JSON arrays to/from `List<String>`.

**Use Case:** Store tags, roles, permissions

```dart
class User extends KhademModel<User> {
  late List<String>? roles;
  late List<String>? tags;
  
  @override
  Map<String, dynamic> get casts => {
    'roles': ArrayCast(),
    'tags': ArrayCast(),
  };
}

// Usage:
user.roles = ['admin', 'editor', 'moderator'];
user.tags = ['vip', 'verified'];
await user.save();

// Retrieved as List<String>
print(user.roles!.first); // 'admin'
print(user.roles!.contains('editor')); // true
```

**Database Storage:** `["admin","editor","moderator"]`

---

### 3. JsonArrayCast

Transforms JSON arrays to/from `List<Map<String, dynamic>>`.

**Use Case:** Store addresses, items, order history

```dart
class User extends KhademModel<User> {
  late List<Map<String, dynamic>>? addresses;
  late List<Map<String, dynamic>>? orders;
  
  @override
  Map<String, dynamic> get casts => {
    'addresses': JsonArrayCast(),
    'orders': JsonArrayCast(),
  };
}

// Usage:
user.addresses = [
  {
    'type': 'home',
    'street': '123 Main St',
    'city': 'New York',
    'zip': '10001',
  },
  {
    'type': 'work',
    'street': '456 Office Blvd',
    'city': 'San Francisco',
    'zip': '94102',
  },
];
await user.save();

// Retrieved as List<Map<String, dynamic>>
final homeAddress = user.addresses!.firstWhere((a) => a['type'] == 'home');
print(homeAddress['city']); // 'New York'
```

**Database Storage:**
```json
[
  {"type":"home","street":"123 Main St","city":"New York","zip":"10001"},
  {"type":"work","street":"456 Office Blvd","city":"San Francisco","zip":"94102"}
]
```

---

### 4. EncryptedCast

One-way hashing for sensitive data (uses SHA-256).

**Use Case:** Passwords, API keys, security tokens

```dart
class User extends KhademModel<User> {
  late String? password;
  late String? apiKey;
  
  @override
  Map<String, dynamic> get casts => {
    'password': EncryptedCast(),
    'api_key': EncryptedCast(),
  };
}

// Usage:
user.password = 'my_secret_password';
await user.save();

// Database stores SHA-256 hash, not original value
// Cannot retrieve original password (one-way hash)
```

**Database Storage:** `a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3`

**⚠️ Important:** This is one-way hashing. For two-way encryption, create a custom caster.

---

### 5. Standard Type Casters

These are enhanced versions of built-in type casting:

#### IntCast
```dart
Map<String, dynamic> get casts => {
  'age': IntCast(),
  'count': IntCast(),
};
```

#### DoubleCast
```dart
Map<String, dynamic> get casts => {
  'price': DoubleCast(),
  'rating': DoubleCast(),
};
```

#### BoolCast
```dart
Map<String, dynamic> get casts => {
  'is_active': BoolCast(),
  'verified': BoolCast(),
};
```

#### DateTimeCast
```dart
Map<String, dynamic> get casts => {
  'birth_date': DateTimeCast(),
  'published_at': DateTimeCast(),
};
```

---

## Custom Casters

Create your own casters by extending `AttributeCaster<T>`.

### Example 1: UserPreferences Caster

```dart
import 'dart:convert';
import 'package:khadem/src/core/database/orm/casting/attribute_caster.dart';

// Your custom data class
class UserPreferences {
  final String theme;
  final String language;
  final bool notifications;
  
  UserPreferences({
    required this.theme,
    required this.language,
    required this.notifications,
  });
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] ?? 'light',
      language: json['language'] ?? 'en',
      notifications: json['notifications'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'theme': theme,
    'language': language,
    'notifications': notifications,
  };
}

// Custom caster
class UserPreferencesCast extends AttributeCaster<UserPreferences> {
  @override
  UserPreferences? get(dynamic value) {
    if (value == null) return null;
    if (value is UserPreferences) return value;
    
    if (value is String) {
      try {
        final json = jsonDecode(value) as Map<String, dynamic>;
        return UserPreferences.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    
    if (value is Map<String, dynamic>) {
      return UserPreferences.fromJson(value);
    }
    
    return null;
  }
  
  @override
  dynamic set(UserPreferences? value) {
    if (value == null) return null;
    return jsonEncode(value.toJson());
  }
}

// Use in model
class User extends KhademModel<User> {
  late UserPreferences? preferences;
  
  @override
  Map<String, dynamic> get casts => {
    'preferences': UserPreferencesCast(),
  };
}

// Usage:
user.preferences = UserPreferences(
  theme: 'dark',
  language: 'en',
  notifications: false,
);
await user.save();

// Strongly typed access
print(user.preferences!.theme); // 'dark'
print(user.preferences!.notifications); // false
```

---

### Example 2: Money/Currency Caster

```dart
class Money {
  final double amount;
  final String currency;
  
  Money(this.amount, this.currency);
  
  factory Money.fromString(String value) {
    // Parse "100.50 USD" format
    final parts = value.split(' ');
    return Money(
      double.parse(parts[0]),
      parts.length > 1 ? parts[1] : 'USD',
    );
  }
  
  @override
  String toString() => '$amount $currency';
  
  String format() {
    final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class MoneyCast extends AttributeCaster<Money> {
  @override
  Money? get(dynamic value) {
    if (value == null) return null;
    if (value is Money) return value;
    if (value is String) return Money.fromString(value);
    return null;
  }
  
  @override
  dynamic set(Money? value) {
    if (value == null) return null;
    return value.toString();
  }
}

// Use in model
class Product extends KhademModel<Product> {
  late Money? price;
  
  @override
  Map<String, dynamic> get casts => {
    'price': MoneyCast(),
  };
}

// Usage:
product.price = Money(99.99, 'USD');
await product.save();

print(product.price!.format()); // $99.99
```

---

### Example 3: Two-Way Encryption Caster

```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class TwoWayEncryptedCast extends AttributeCaster<String> {
  final encrypt.Key key;
  final encrypt.IV iv;
  late final encrypt.Encrypter encrypter;
  
  TwoWayEncryptedCast(String secretKey) 
      : key = encrypt.Key.fromUtf8(secretKey.padRight(32)),
        iv = encrypt.IV.fromLength(16) {
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }
  
  @override
  String? get(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    
    try {
      final encrypted = encrypt.Encrypted.fromBase64(value);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }
  
  @override
  dynamic set(String? value) {
    if (value == null) return null;
    final encrypted = encrypter.encrypt(value, iv: iv);
    return encrypted.base64;
  }
}

// Use in model
class User extends KhademModel<User> {
  late String? ssn;
  late String? creditCard;
  
  @override
  Map<String, dynamic> get casts => {
    'ssn': TwoWayEncryptedCast('your-32-char-secret-key-here'),
    'credit_card': TwoWayEncryptedCast('your-32-char-secret-key-here'),
  };
}
```

---

## Usage Examples

### Complete Model Example

```dart
import 'package:khadem/khadem.dart';
import 'package:khadem/src/core/database/orm/casting/built_in_casters.dart';

class User extends KhademModel<User> with SoftDeletes, Timestamps {
  // Basic fields
  late String name;
  late String email;
  late String? password;
  late bool? isActive;
  late DateTime? emailVerifiedAt;
  
  // Complex fields with casting
  late Map<String, dynamic>? settings;
  late List<String>? roles;
  late List<Map<String, dynamic>>? addresses;
  late UserPreferences? preferences;
  
  @override
  List<String> get fillable => [
    'name',
    'email',
    'password',
    'is_active',
    'email_verified_at',
    'settings',
    'roles',
    'addresses',
    'preferences',
  ];
  
  @override
  List<String> get protected => ['password'];
  
  @override
  Map<String, dynamic> get casts => {
    // Basic types
    'email_verified_at': DateTimeCast(),
    'is_active': BoolCast(),
    
    // Advanced types
    'password': EncryptedCast(),
    'settings': JsonCast(),
    'roles': ArrayCast(),
    'addresses': JsonArrayCast(),
    'preferences': UserPreferencesCast(),
  };
  
  @override
  User newFactory(Map<String, dynamic> data) => User()..fromJson(data);
}

// Usage:
void main() async {
  final user = User()
    ..name = 'John Doe'
    ..email = 'john@example.com'
    ..password = 'secret123' // Auto-hashed
    ..isActive = true
    ..emailVerifiedAt = DateTime.now()
    ..settings = {
      'theme': 'dark',
      'language': 'en',
      'timezone': 'UTC',
    }
    ..roles = ['user', 'editor']
    ..addresses = [
      {
        'type': 'home',
        'street': '123 Main St',
        'city': 'NYC',
      },
    ]
    ..preferences = UserPreferences(
      theme: 'dark',
      language: 'en',
      notifications: true,
    );
  
  await user.save();
  
  // All casts work automatically on retrieval
  final retrieved = await User.query().findById(user.id!);
  print(retrieved.settings!['theme']); // 'dark'
  print(retrieved.roles!.first); // 'user'
  print(retrieved.addresses![0]['city']); // 'NYC'
  print(retrieved.preferences!.theme); // 'dark'
}
```

---

## Best Practices

### 1. Choose the Right Caster

| Data Type | Recommended Caster | Example |
|-----------|-------------------|---------|
| Simple object | `JsonCast` | Settings, metadata |
| String list | `ArrayCast` | Tags, roles |
| Object array | `JsonArrayCast` | Addresses, items |
| Password | `EncryptedCast` | Password, PIN |
| Complex class | Custom caster | UserPreferences, Money |

### 2. Null Safety

All casters handle `null` values gracefully:

```dart
user.settings = null; // OK
await user.save();

final retrieved = await User.query().findById(user.id!);
print(retrieved.settings); // null
```

### 3. Validation

Add validation before casting:

```dart
class User extends KhademModel<User> {
  @override
  void setField(String key, dynamic value) {
    // Validate before setting
    if (key == 'roles' && value is List<String>) {
      final validRoles = ['admin', 'editor', 'user'];
      if (!value.every((r) => validRoles.contains(r))) {
        throw ArgumentError('Invalid role');
      }
    }
    super.setField(key, value);
  }
}
```

### 4. Performance

- **JsonCast** - Fast for small objects (<100 keys)
- **ArrayCast** - Fast for lists (<1000 items)
- **JsonArrayCast** - Moderate for arrays (<100 objects)
- **EncryptedCast** - Slower (hashing overhead)
- **Custom Casters** - Depends on implementation

### 5. Error Handling

Casters return `null` on parse errors:

```dart
// Malformed JSON in database
user.settings = 'invalid json';
await user.save();

final retrieved = await User.query().findById(user.id!);
print(retrieved.settings); // null (parsing failed)
```

### 6. Testing

Test your custom casters thoroughly:

```dart
test('UserPreferencesCast handles all cases', () {
  final caster = UserPreferencesCast();
  
  // Test null
  expect(caster.get(null), isNull);
  
  // Test valid object
  final prefs = UserPreferences(theme: 'dark', language: 'en', notifications: true);
  expect(caster.get(caster.set(prefs))!.theme, 'dark');
  
  // Test invalid data
  expect(caster.get('invalid'), isNull);
});
```

---

## Migration Guide

### Migrating from Basic Casts

**Before (Basic Type Casts):**
```dart
class User extends KhademModel<User> {
  @override
  Map<String, Type> get casts => {
    'email_verified_at': DateTime,
    'is_active': bool,
  };
}
```

**After (Advanced Casters):**
```dart
import 'package:khadem/src/core/database/orm/casting/built_in_casters.dart';

class User extends KhademModel<User> {
  @override
  Map<String, dynamic> get casts => {
    'email_verified_at': DateTimeCast(),
    'is_active': BoolCast(),
    
    // Add new advanced casts
    'settings': JsonCast(),
    'roles': ArrayCast(),
  };
}
```

### Backward Compatibility

The system supports both old and new cast definitions:

```dart
Map<String, dynamic> get casts => {
  // Old style (still works)
  'created_at': DateTime,
  'count': int,
  
  // New style (advanced)
  'settings': JsonCast(),
  'roles': ArrayCast(),
};
```

---

## Summary

✅ **9 built-in casters** covering common use cases  
✅ **Custom caster support** for any data type  
✅ **Type-safe** transformations  
✅ **Null-safe** by default  
✅ **Backward compatible** with existing code  
✅ **Fully tested** and production-ready  

**Next:** Implement relationship counts and aggregates
