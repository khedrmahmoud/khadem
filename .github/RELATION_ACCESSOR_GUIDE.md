# Direct Relation Accessor Pattern Guide

**Status:** ✅ Pattern Established - Manual Implementation Required  
**Date:** October 9, 2025

## Overview

While automatic code generation for relation accessors is planned for the future, you can **manually implement** direct relation accessors in your models today. This guide shows the recommended patterns.

## Why Use Direct Accessors?

### Before (Verbose & Untyped)
```dart
final posts = (user.getRelation('posts') as List<Post>?) ?? [];
final author = post.getRelation('author') as User?;
final users = (chatRoom.getRelation('users') as List<ChatRoomUser>)
    .firstWhere((user) => user.id != currentUserId);
```

### After (Clean & Type-Safe)
```dart
final posts = user.posts; // List<Post>
final author = post.author; // User?
final users = chatRoom.users
    .firstWhere((user) => user.id != currentUserId);
```

## Implementation Patterns

### 1. Basic Synchronous Accessors

For relations that are **already loaded** (via eager loading or manual loading):

```dart
class User extends KhademModel<User> {
  // ... other properties ...
  
  // HasMany relation
  List<Post> get posts => getRelation('posts') ?? [];
  
  // BelongsTo relation  
  Profile? get profile => getRelation('profile');
  
  // HasOne relation
  Address? get address => getRelation('address');
  
  // BelongsToMany relation
  List<Role> get roles => getRelation('roles') ?? [];
}
```

**Usage:**
```dart
// Eager load first
final user = await User.query()
    .withRelations(['posts', 'profile'])
    .findById(1);

// Now access directly
print(user.posts.length); // Type-safe!
print(user.profile?.bio);
```

### 2. Async Accessors with Lazy Loading

For relations that **auto-load** when accessed:

```dart
class User extends KhademModel<User> {
  // Sync accessor (returns loaded or empty)
  List<Post> get posts => getRelation('posts') ?? [];
  
  // Async accessor (loads if not loaded)
  Future<List<Post>> get postsAsync async {
    if (!isRelationLoaded('posts')) {
      await loadRelation('posts');
    }
    return posts;
  }
  
  // Same pattern for BelongsTo
  Profile? get profile => getRelation('profile');
  
  Future<Profile?> get profileAsync async {
    if (!isRelationLoaded('profile')) {
      await loadRelation('profile');
    }
    return profile;
  }
}
```

**Usage:**
```dart
final user = await User.query().findById(1);

// Lazy load on first access
final posts = await user.postsAsync; // Loads from DB
final profile = await user.profileAsync; // Loads from DB

// Subsequent access uses cached data
final morePosts = user.posts; // Already loaded
```

### 3. Combined Pattern (Recommended)

Best practice: Provide **both sync and async** accessors:

```dart
class ChatRoom extends KhademModel<ChatRoom> {
  // Default relations to always load
  @override
  List<dynamic> get defaultRelations => ['users.user', 'owner'];
  
  // Sync accessors (for when eager loaded)
  List<ChatRoomUser> get users => getRelation('users') ?? [];
  User? get owner => getRelation('owner');
  
  // Async accessors (with lazy loading)
  Future<List<ChatRoomUser>> get usersAsync async {
    if (!isRelationLoaded('users')) {
      await loadRelation('users');
    }
    return users;
  }
  
  Future<User?> get ownerAsync async {
    if (!isRelationLoaded('owner')) {
      await loadRelation('owner');
    }
    return owner;
  }
  
  // Computed properties can use sync accessors (if defaultRelations loads them)
  @override
  Map<String, dynamic> get computed => {
    'users_count': () => users.length, // Uses sync accessor
    'owner_name': () => owner?.name ?? 'Unknown',
  };
}
```

**Usage:**
```dart
// With default relations (auto-loaded)
final room = await ChatRoom.query().findById(1);
print(room.users.length); // Already loaded via defaultRelations
print(room.owner?.name);

// Without default loading
final lightRoom = await ChatRoom.query()
    .withOnly([]) // Don't load defaults
    .findById(1);
    
// Use async accessors for lazy loading
final users = await lightRoom.usersAsync; // Loads on demand
```

### 4. Nested Relations

For accessing nested relations:

```dart
class ChatRoomUser extends KhademModel<ChatRoomUser> {
  // Direct relation to User
  User? get user => getRelation('user');
  
  Future<User?> get userAsync async {
    if (!isRelationLoaded('user')) {
      await loadRelation('user');
    }
    return user;
  }
}

class ChatRoom extends KhademModel<ChatRoom> {
  @override
  List<dynamic> get defaultRelations => ['users.user']; // Nested!
  
  List<ChatRoomUser> get users => getRelation('users') ?? [];
  
  // Helper to get User objects directly
  List<User> get allUsers {
    return users
        .where((roomUser) => roomUser.user != null)
        .map((roomUser) => roomUser.user!)
        .toList();
  }
  
  // Get other user in private chat
  User? getOtherUser(dynamic currentUserId) {
    if (users.isEmpty) return null;
    
    final otherRoomUser = users.firstWhere(
      (roomUser) => roomUser.userId.toString() != currentUserId.toString(),
      orElse: () => users.first,
    );
    
    return otherRoomUser.user;
  }
}
```

**Usage:**
```dart
final room = await ChatRoom.query().findById(1); // Loads users.user

// Access nested relation
final allUsers = room.allUsers; // List<User>
final otherUser = room.getOtherUser(RequestContext.userId);

print(otherUser?.name);
```

## Naming Conventions

### Sync Accessors
- Use the **relation name** as the getter name
- Examples: `posts`, `profile`, `owner`, `comments`

### Async Accessors  
- Append `Async` to the relation name
- Examples: `postsAsync`, `profileAsync`, `ownerAsync`

### Helper Methods
- Use descriptive names for computed relation helpers
- Examples: `allUsers`, `getOtherUser()`, `activeComments`

## Type Safety Guidelines

### 1. Always Specify Return Types

```dart
// ✅ Good - Type-safe
List<Post> get posts => getRelation('posts') ?? [];
User? get author => getRelation('author');

// ❌ Bad - Loses type information
dynamic get posts => getRelation('posts');
```

### 2. Handle Null Cases

```dart
// ✅ Good - Safe defaults
List<Post> get posts => getRelation('posts') ?? [];
List<Comment> get comments => getRelation('comments') ?? <Comment>[];

// ❌ Bad - Can throw null errors
List<Post> get posts => getRelation('posts');
```

### 3. Use Nullable Types for BelongsTo/HasOne

```dart
// ✅ Good - Nullable for singular relations
User? get author => getRelation('author');
Profile? get profile => getRelation('profile');

// ❌ Bad - Non-nullable can cause errors
User get author => getRelation('author');
```

## Working with Async Computed Properties

Combine relation accessors with async computed properties:

```dart
class ChatRoom extends KhademModel<ChatRoom> {
  @override
  List<dynamic> get defaultRelations => ['users.user', 'owner'];
  
  // Sync accessors
  List<ChatRoomUser> get users => getRelation('users') ?? [];
  User? get owner => getRelation('owner');
  
  @override
  Map<String, dynamic> get computed => {
    // Sync computed using sync accessors
    'users_count': () => users.length,
    'is_private': () => type == 'private',
    
    // Async computed for complex logic
    'display_name': () async {
      if (type == 'private' && name == null) {
        final otherUser = getOtherUser(RequestContext.userId);
        return otherUser?.name ?? 'Private Chat';
      }
      return name ?? 'Group Chat';
    },
    
    // Async computed with lazy loading
    'owner_email': () async {
      final ownerData = await ownerAsync; // Lazy loads if needed
      return ownerData?.email ?? 'Unknown';
    },
  };
  
  User? getOtherUser(dynamic currentUserId) {
    if (users.isEmpty) return null;
    
    final otherRoomUser = users.firstWhere(
      (roomUser) => roomUser.userId.toString() != currentUserId.toString(),
      orElse: () => users.first,
    );
    
    return otherRoomUser.user;
  }
}
```

## Performance Considerations

### 1. Prefer Sync Accessors with Default Relations

```dart
class Post extends KhademModel<Post> {
  // Load frequently needed relations by default
  @override
  List<dynamic> get defaultRelations => ['author', 'comments'];
  
  // Use sync accessors (already loaded)
  User? get author => getRelation('author');
  List<Comment> get comments => getRelation('comments') ?? [];
  
  // Computed properties are fast
  @override
  Map<String, dynamic> get computed => {
    'author_name': () => author?.name ?? 'Unknown',
    'comment_count': () => comments.length,
  };
}
```

### 2. Use Async Accessors Sparingly

Only create async accessors for relations that are **sometimes** needed:

```dart
class User extends KhademModel<User> {
  // Common relations in default
  @override
  List<dynamic> get defaultRelations => ['profile'];
  
  Profile? get profile => getRelation('profile');
  
  // Rarely needed - async only
  Future<List<Order>> get ordersAsync async {
    if (!isRelationLoaded('orders')) {
      await loadRelation('orders');
    }
    return getRelation('orders') ?? [];
  }
}
```

### 3. Batch Loading vs Lazy Loading

```dart
// ✅ Good - Batch load for multiple records
final users = await User.query()
    .withRelations(['posts', 'profile'])
    .get(); // Efficient: 3 queries total

for (final user in users) {
  print(user.posts.length); // No additional queries
}

// ❌ Bad - Lazy load in loop (N+1 problem)
final users = await User.query().get();

for (final user in users) {
  final posts = await user.postsAsync; // N additional queries!
  print(posts.length);
}
```

## Complete Example

```dart
class User extends KhademModel<User> {
  int? id;
  String? name;
  String? email;
  
  // Default relations
  @override
  List<dynamic> get defaultRelations => ['profile'];
  
  // Fillable
  @override
  List<String> get fillable => ['name', 'email'];
  
  // Guarded
  @override
  List<String> get guarded => ['id', 'email_verified_at'];
  
  // Protected from JSON
  @override
  List<String> get protected => ['password'];
  
  // Relations
  @override
  Map<String, RelationDefinition> get relations => {
    'posts': RelationDefinition.hasMany(
      relatedTable: 'posts',
      foreignKey: 'user_id',
      localKey: 'id',
      factory: () => Post(),
    ),
    'profile': RelationDefinition.hasOne(
      relatedTable: 'profiles',
      foreignKey: 'user_id',
      localKey: 'id',
      factory: () => Profile(),
    ),
    'roles': RelationDefinition.belongsToMany(
      relatedTable: 'roles',
      pivotTable: 'user_roles',
      foreignPivotKey: 'user_id',
      relatedPivotKey: 'role_id',
      factory: () => Role(),
    ),
  };
  
  // Direct relation accessors (sync)
  List<Post> get posts => getRelation('posts') ?? [];
  Profile? get profile => getRelation('profile');
  List<Role> get roles => getRelation('roles') ?? [];
  
  // Async accessors with lazy loading
  Future<List<Post>> get postsAsync async {
    if (!isRelationLoaded('posts')) {
      await loadRelation('posts');
    }
    return posts;
  }
  
  Future<Profile?> get profileAsync async {
    if (!isRelationLoaded('profile')) {
      await loadRelation('profile');
    }
    return profile;
  }
  
  // Computed properties
  @override
  Map<String, dynamic> get computed => {
    'full_name': () => '$name (${profile?.bio ?? "No bio"})',
    'posts_count': () async {
      final userPosts = await postsAsync;
      return userPosts.length;
    },
  };
  
  // Required methods
  @override
  User newFactory(Map<String, dynamic> data) => User()..fromJson(data);
  
  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id': return id;
      case 'name': return name;
      case 'email': return email;
      default: return null;
    }
  }
  
  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id': id = value; break;
      case 'name': name = value; break;
      case 'email': email = value; break;
    }
  }
}
```

## Future Enhancements

### Code Generation (Planned)

In the future, we plan to add code generation to automatically create relation accessors:

```dart
// Will generate getters automatically from relations map
@GenerateRelationAccessors()
class User extends KhademModel<User> {
  // Relations defined here...
  
  // Accessors auto-generated:
  // List<Post> get posts => getRelation('posts') ?? [];
  // Profile? get profile => getRelation('profile');
  // etc.
}
```

Until then, manually implement the pattern shown in this guide.

---

**Last Updated:** October 9, 2025  
**Phase:** 1 (Complete)  
**Next:** Query Scopes (Phase 2)
