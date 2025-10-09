# Query Scopes Implementation Guide

**Status:** ✅ Pattern Established - Manual Implementation  
**Date:** October 9, 2025  
**Phase:** 2

## Overview

Query scopes allow you to define reusable, chainable query constraints on your models. They make your code more readable, maintainable, and DRY (Don't Repeat Yourself).

## Basic Usage

### 1. Define Scopes on Your Model

```dart
import 'package:khadem/khadem.dart';

class User extends KhademModel<User> with QueryScopes {
  int? id;
  String? name;
  String? email;
  bool? active;
  DateTime? emailVerifiedAt;
  String? role;
  
  // Define scopes
  QueryBuilderInterface<User> scopeActive(QueryBuilderInterface<User> query) {
    return query.where('active', '=', true);
  }
  
  QueryBuilderInterface<User> scopeVerified(QueryBuilderInterface<User> query) {
    return query.whereNotNull('email_verified_at');
  }
  
  QueryBuilderInterface<User> scopeRole(
    QueryBuilderInterface<User> query,
    String role,
  ) {
    return query.where('role', '=', role);
  }
  
  QueryBuilderInterface<User> scopeSearch(
    QueryBuilderInterface<User> query,
    String search,
  ) {
    return query
        .where('name', 'LIKE', '%$search%')
        .orWhere('email', 'LIKE', '%$search%');
  }
  
  // ... other model code ...
}
```

### 2. Use Scopes in Queries

**Note:** Currently, scopes need to be called explicitly as methods on your model. We're working on automatic scope detection for the query builder.

```dart
// Manual scope application
final users = await User.query()
    .where((q) => User().scopeActive(q))
    .where((q) => User().scopeVerified(q))
    .get();

// Or create a helper method:
class User extends KhademModel<User> with QueryScopes {
  // ... scopes ...
  
  static QueryBuilderInterface<User> active(QueryBuilderInterface<User> query) {
    return User().scopeActive(query);
  }
  
  static QueryBuilderInterface<User> verified(QueryBuilderInterface<User> query) {
    return User().scopeVerified(query);
  }
}

// Then use:
final users = await User.query()
    .applyScope(User.active)
    .applyScope(User.verified)
    .get();
```

## Scope Patterns

### 1. Simple Boolean Scopes

For filtering by true/false values:

```dart
class Post extends KhademModel<Post> with QueryScopes {
  QueryBuilderInterface<Post> scopePublished(QueryBuilderInterface<Post> query) {
    return query.where('published', '=', true);
  }
  
  QueryBuilderInterface<Post> scopeDraft(QueryBuilderInterface<Post> query) {
    return query.where('published', '=', false);
  }
  
  QueryBuilderInterface<Post> scopeFeatured(QueryBuilderInterface<Post> query) {
    return query.where('featured', '=', true);
  }
}
```

### 2. Parameterized Scopes

Scopes that accept parameters:

```dart
class Product extends KhademModel<Product> with QueryScopes {
  QueryBuilderInterface<Product> scopeCategory(
    QueryBuilderInterface<Product> query,
    String category,
  ) {
    return query.where('category', '=', category);
  }
  
  QueryBuilderInterface<Product> scopePriceRange(
    QueryBuilderInterface<Product> query,
    double min,
    double max,
  ) {
    return query.whereBetween('price', min, max);
  }
  
  QueryBuilderInterface<Product> scopeInStock(
    QueryBuilderInterface<Product> query, {
    int threshold = 1,
  }) {
    return query.where('stock', '>=', threshold);
  }
}
```

### 3. Date-Based Scopes

Common date filtering patterns:

```dart
class Order extends KhademModel<Order> with QueryScopes {
  QueryBuilderInterface<Order> scopeToday(QueryBuilderInterface<Order> query) {
    final today = DateTime.now();
    return query.whereDate('created_at', today.toString().split(' ')[0]);
  }
  
  QueryBuilderInterface<Order> scopeThisWeek(QueryBuilderInterface<Order> query) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return query.where('created_at', '>=', weekStart);
  }
  
  QueryBuilderInterface<Order> scopeThisMonth(QueryBuilderInterface<Order> query) {
    return query.whereMonth('created_at', DateTime.now().month);
  }
  
  QueryBuilderInterface<Order> scopeThisYear(QueryBuilderInterface<Order> query) {
    return query.whereYear('created_at', DateTime.now().year);
  }
  
  QueryBuilderInterface<Order> scopeRecent(
    QueryBuilderInterface<Order> query, {
    int days = 7,
  }) {
    final date = DateTime.now().subtract(Duration(days: days));
    return query.where('created_at', '>=', date);
  }
}
```

### 4. Relationship Scopes

Scopes that filter by relationships:

```dart
class Post extends KhademModel<Post> with QueryScopes {
  QueryBuilderInterface<Post> scopeByAuthor(
    QueryBuilderInterface<Post> query,
    int authorId,
  ) {
    return query.where('author_id', '=', authorId);
  }
  
  QueryBuilderInterface<Post> scopeHasComments(
    QueryBuilderInterface<Post> query,
  ) {
    return query.whereHas('comments', (q) {
      // Post has at least one comment
    });
  }
  
  QueryBuilderInterface<Post> scopePopular(
    QueryBuilderInterface<Post> query, {
    int minComments = 10,
  }) {
    return query.whereHas('comments', (q) {
      q.having('COUNT(*)', '>=', minComments);
    });
  }
}
```

### 5. Complex Scopes

Scopes with multiple conditions:

```dart
class User extends KhademModel<User> with QueryScopes {
  QueryBuilderInterface<User> scopeActiveMembers(
    QueryBuilderInterface<User> query,
  ) {
    return query
        .where('active', '=', true)
        .whereNotNull('email_verified_at')
        .where('role', '!=', 'guest');
  }
  
  QueryBuilderInterface<User> scopeAdmins(QueryBuilderInterface<User> query) {
    return query.whereIn('role', ['admin', 'super_admin']);
  }
  
  QueryBuilderInterface<User> scopeSearch(
    QueryBuilderInterface<User> query,
    String term,
  ) {
    return query.where((q) {
      q.whereLike('name', '%$term%')
       .orWhere('email', 'LIKE', '%$term%')
       .orWhere('phone', 'LIKE', '%$term%');
    });
  }
}
```

### 6. Ordering Scopes

Scopes that apply ordering:

```dart
class Post extends KhademModel<Post> with QueryScopes {
  QueryBuilderInterface<Post> scopeLatest(QueryBuilderInterface<Post> query) {
    return query.orderBy('created_at', direction: 'DESC');
  }
  
  QueryBuilderInterface<Post> scopeOldest(QueryBuilderInterface<Post> query) {
    return query.orderBy('created_at', direction: 'ASC');
  }
  
  QueryBuilderInterface<Post> scopePopular(QueryBuilderInterface<Post> query) {
    return query.orderBy('views', direction: 'DESC');
  }
  
  QueryBuilderInterface<Post> scopeAlphabetical(
    QueryBuilderInterface<Post> query,
  ) {
    return query.orderBy('title', direction: 'ASC');
  }
}
```

## Advanced Patterns

### 1. Conditional Scopes

Scopes that apply conditions based on parameters:

```dart
class Product extends KhademModel<Product> with QueryScopes {
  QueryBuilderInterface<Product> scopeFilter(
    QueryBuilderInterface<Product> query, {
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
  }) {
    var q = query;
    
    if (category != null) {
      q = q.where('category', '=', category);
    }
    
    if (minPrice != null) {
      q = q.where('price', '>=', minPrice);
    }
    
    if (maxPrice != null) {
      q = q.where('price', '<=', maxPrice);
    }
    
    if (inStock == true) {
      q = q.where('stock', '>', 0);
    }
    
    return q;
  }
}

// Usage:
final products = await Product().scopeFilter(
  Product.query(),
  category: 'electronics',
  minPrice: 100,
  inStock: true,
);
```

### 2. Scope Composition

Scopes that use other scopes:

```dart
class User extends KhademModel<User> with QueryScopes {
  QueryBuilderInterface<User> scopeActive(QueryBuilderInterface<User> query) {
    return query.where('active', '=', true);
  }
  
  QueryBuilderInterface<User> scopeVerified(QueryBuilderInterface<User> query) {
    return query.whereNotNull('email_verified_at');
  }
  
  // Composite scope
  QueryBuilderInterface<User> scopeTrustedUsers(
    QueryBuilderInterface<User> query,
  ) {
    return scopeVerified(scopeActive(query));
  }
  
  // Or using a helper
  QueryBuilderInterface<User> scopePremiumMembers(
    QueryBuilderInterface<User> query,
  ) {
    var q = scopeTrustedUsers(query);
    return q.where('subscription', '=', 'premium');
  }
}
```

### 3. Global Scopes (Pattern)

While true global scopes aren't implemented yet, you can achieve similar behavior:

```dart
abstract class TenantModel<T> extends KhademModel<T> {
  int? get tenantId;
  
  /// Override query to always filter by tenant
  @override
  QueryBuilderInterface<T> get query {
    final baseQuery = super.query;
    final currentTenantId = RequestContext.get<int>('tenant_id');
    
    if (currentTenantId != null) {
      return baseQuery.where('tenant_id', '=', currentTenantId);
    }
    
    return baseQuery;
  }
}

class User extends TenantModel<User> {
  int? tenantId;
  
  // All queries automatically filtered by tenant!
  // No need to add .where('tenant_id', '=', ...) every time
}
```

## Real-World Example

```dart
class ChatRoom extends KhademModel<ChatRoom> with QueryScopes {
  int? id;
  String? name;
  String type; // 'private' or 'group'
  int? ownerId;
  bool? active;
  DateTime? createdAt;
  
  @override
  List<dynamic> get defaultRelations => ['users.user', 'owner'];
  
  // Scopes
  QueryBuilderInterface<ChatRoom> scopePrivate(
    QueryBuilderInterface<ChatRoom> query,
  ) {
    return query.where('type', '=', 'private');
  }
  
  QueryBuilderInterface<ChatRoom> scopeGroup(
    QueryBuilderInterface<ChatRoom> query,
  ) {
    return query.where('type', '=', 'group');
  }
  
  QueryBuilderInterface<ChatRoom> scopeActive(
    QueryBuilderInterface<ChatRoom> query,
  ) {
    return query.where('active', '=', true);
  }
  
  QueryBuilderInterface<ChatRoom> scopeForUser(
    QueryBuilderInterface<ChatRoom> query,
    int userId,
  ) {
    return query.whereHas('users', (q) {
      q.where('user_id', '=', userId);
    });
  }
  
  QueryBuilderInterface<ChatRoom> scopeOwnedBy(
    QueryBuilderInterface<ChatRoom> query,
    int userId,
  ) {
    return query.where('owner_id', '=', userId);
  }
  
  QueryBuilderInterface<ChatRoom> scopeSearch(
    QueryBuilderInterface<ChatRoom> query,
    String search,
  ) {
    return query.where((q) {
      q.whereLike('name', '%$search%')
       .orWhereHas('users.user', (userQ) {
         userQ.whereLike('name', '%$search%');
       });
    });
  }
  
  QueryBuilderInterface<ChatRoom> scopeRecent(
    QueryBuilderInterface<ChatRoom> query,
  ) {
    return query.orderBy('created_at', direction: 'DESC');
  }
  
  // Static helpers for easier usage
  static QueryBuilderInterface<ChatRoom> applyPrivate(
    QueryBuilderInterface<ChatRoom> query,
  ) => ChatRoom().scopePrivate(query);
  
  static QueryBuilderInterface<ChatRoom> applyForUser(
    QueryBuilderInterface<ChatRoom> query,
    int userId,
  ) => ChatRoom().scopeForUser(query, userId);
  
  // ... other model code ...
}

// Usage:
void main() async {
  final userId = 123;
  
  // Get active private chats for user
  final privateChats = await ChatRoom().scopeRecent(
    ChatRoom().scopeActive(
      ChatRoom().scopePrivate(
        ChatRoom().scopeForUser(
          ChatRoom.query(),
          userId,
        ),
      ),
    ),
  ).get();
  
  // Or with static helpers:
  final rooms = await ChatRoom.query()
      .apply(ChatRoom.applyPrivate)
      .apply((q) => ChatRoom.applyForUser(q, userId))
      .get();
}
```

## Best Practices

### 1. Naming Conventions

- **Prefix with `scope`**: All scope methods must start with `scope`
- **Use descriptive names**: `scopeActive()`, not `scopeA()`
- **Use verbs for actions**: `scopeSearch()`, `scopeFilter()`
- **Use adjectives for states**: `scopeActive()`, `scopeVerified()`

### 2. Keep Scopes Focused

```dart
// ✅ Good - Single responsibility
QueryBuilderInterface<Post> scopePublished(QueryBuilderInterface<Post> query) {
  return query.where('published', '=', true);
}

QueryBuilderInterface<Post> scopeFeatured(QueryBuilderInterface<Post> query) {
  return query.where('featured', '=', true);
}

// ❌ Bad - Too much in one scope
QueryBuilderInterface<Post> scopeGetAllPublishedFeaturedPostsByAuthor(
  QueryBuilderInterface<Post> query,
  int authorId,
) {
  return query
      .where('published', '=', true)
      .where('featured', '=', true)
      .where('author_id', '=', authorId)
      .orderBy('created_at', direction: 'DESC');
}
```

### 3. Compose Scopes

```dart
// ✅ Good - Reusable, composable
QueryBuilderInterface<User> scopeActive(QueryBuilderInterface<User> query) {
  return query.where('active', '=', true);
}

QueryBuilderInterface<User> scopeVerified(QueryBuilderInterface<User> query) {
  return query.whereNotNull('email_verified_at');
}

QueryBuilderInterface<User> scopeTrusted(QueryBuilderInterface<User> query) {
  return scopeVerified(scopeActive(query));
}
```

### 4. Document Complex Scopes

```dart
/// Filters users who are considered "premium members"
/// 
/// A premium member is:
/// - Active account
/// - Verified email
/// - Has an active subscription
/// - Not banned
QueryBuilderInterface<User> scopePremiumMembers(
  QueryBuilderInterface<User> query,
) {
  return query
      .where('active', '=', true)
      .whereNotNull('email_verified_at')
      .whereHas('subscription', (q) {
        q.where('status', '=', 'active');
      })
      .where('banned', '=', false);
}
```

## Future Enhancements

### Automatic Scope Detection (Planned)

In the future, the query builder will automatically detect and apply scopes:

```dart
// Future syntax:
final users = await User.query()
    .active()          // Automatically calls scopeActive
    .verified()        // Automatically calls scopeVerified
    .role('admin')     // Automatically calls scopeRole
    .get();
```

Until then, use the manual patterns shown in this guide.

---

**Last Updated:** October 9, 2025  
**Phase:** 2  
**Status:** Pattern Documented  
**Next:** Soft Deletes Mixin
