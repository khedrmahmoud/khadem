# Khadem Model System Enhancement Analysis

**Date:** October 5, 2025  
**Current Branch:** dev  
**Purpose:** Comprehensive analysis and enhancement plan for the Khadem ORM model system

---

## 📊 Current State Analysis

### Existing Components

#### 1. **KhademModel** (Core Abstract Class)
**Location:** `lib/src/core/database/model_base/khadem_model.dart`

**Current Features:**
- ✅ Basic CRUD operations (`save()`, `delete()`, `refresh()`)
- ✅ Relation loading (`load()`, `loadRelation()`, `loadMissing()`)
- ✅ JSON serialization (`toJson()`, `fromJson()`)
- ✅ Computed properties (`computed` map, `getComputedAttribute()`)
- ✅ Hidden attributes (`hidden` list)
- ✅ Appended attributes (`appends` list)
- ✅ Type casting (`casts` map)
- ✅ Fillable fields (`fillable` list)
- ✅ Attribute visibility (`makeVisible()`, `makeHidden()`)
- ✅ Selective serialization (`only()`, `except()`)
- ✅ Query builder access (`query` getter)

**Current Limitations:**
- ❌ Computed properties are synchronous only (no `Future<dynamic>` support)
- ❌ Relations not directly accessible as model properties
- ❌ No `guarded` (blacklist) mechanism for mass assignment
- ❌ No `protected` attributes
- ❌ No query scopes
- ❌ No soft delete support
- ❌ No automatic timestamps (`created_at`, `updated_at`)
- ❌ No model observers/lifecycle hooks (only events)
- ❌ `fillable` is whitelist-only, no flexible mass assignment control

#### 2. **RelationModel** (Relation Management)
**Location:** `lib/src/core/database/model_base/relation_model.dart`

**Current Features:**
- ✅ Relation storage (`set()`, `get()`)
- ✅ Loaded state checking (`isLoaded()`)
- ✅ Relation serialization (`toJson()`)

**Current Limitations:**
- ❌ Relations stored in internal `_loaded` map, not directly accessible
- ❌ No typed getters (always returns `dynamic`)
- ❌ No lazy loading when accessing unloaded relations
- ❌ Cannot access relations like `model.posts` or `model.user`
- ❌ Must use `getRelation('posts')` which is verbose

**Example Problem:**
```dart
// Current (verbose and untyped):
final users = (chatRoom.getRelation('users') as List<ChatRoomUser>)
    .firstWhere((user) => user.id != currentUserId);
    
// Desired (clean and typed):
final users = chatRoom.users
    .firstWhere((user) => user.id != currentUserId);
```

#### 3. **JsonModel** (Serialization)
**Location:** `lib/src/core/database/model_base/json_model.dart`

**Current Features:**
- ✅ Raw data storage
- ✅ Type casting (`DateTime`, `int`, `double`, `bool`, `Blob`)
- ✅ JSON serialization with hidden fields
- ✅ Computed attribute inclusion
- ✅ Database JSON generation (fillable only)

**Current Limitations:**
- ❌ No support for custom casters
- ❌ No array/collection casting
- ❌ No encrypted attribute support
- ❌ No automatic date formatting
- ❌ Computed properties can't be async

#### 4. **DatabaseModel** (Persistence)
**Location:** `lib/src/core/database/model_base/database_model.dart`

**Current Features:**
- ✅ Save (insert/update)
- ✅ Delete
- ✅ Find by ID
- ✅ Refresh from database
- ✅ Basic validation (column names, operators)
- ✅ Events (beforeCreate, afterCreate, etc.)

**Current Limitations:**
- ❌ No soft delete support
- ❌ No timestamps handling (`created_at`, `updated_at`)
- ❌ No batch operations
- ❌ No upsert functionality
- ❌ Delete is hard delete only

#### 5. **EventModel** (Lifecycle Events)
**Location:** `lib/src/core/database/model_base/event_model.dart`

**Current Features:**
- ✅ Event firing for CRUD operations
- ✅ Before/after hooks (creating, created, updating, updated, deleting, deleted)

**Current Limitations:**
- ❌ No model observers pattern
- ❌ No way to halt operations (e.g., prevent delete)
- ❌ No retrieving/retrieved events
- ❌ No saving/saved events

#### 6. **EagerLoader** (Relation Loading)
**Location:** `lib/src/core/database/database_drivers/mysql/eager_loader.dart`

**Current Features:**
- ✅ Eager loading via `withRelations()`
- ✅ Nested relations (`'user.posts.comments'`)
- ✅ Pagination support
- ✅ Query constraints on relations
- ✅ All relation types (hasOne, hasMany, belongsTo, belongsToMany, morph)

**Current Limitations:**
- ❌ No `with()` method (only `withRelations()`)
- ❌ Loaded relations not directly accessible on model

---

## 🎯 Enhancement Goals

### Priority 1: Essential Enhancements

#### 1.1 Model-Level Default Eager Loading (`with` Property) ⭐⭐⭐
**Goal:** Define default relations to always eager load at model level

**Current:**
```dart
// Must manually eager load every time
final users = await User.query().withRelations(['posts', 'profile']).get();
final user = await User.query().withRelations(['posts']).findById(1);
```

**Desired:**
```dart
class User extends KhademModel<User> {
  // Define default relations to always load
  @override
  List<dynamic> get with => ['posts', 'profile'];
  
  // Or with nested relations
  @override
  List<dynamic> get with => ['posts.comments', 'profile', 'roles'];
}

// Now these automatically load posts and profile:
final users = await User.query().get(); // Auto-loads posts, profile
final user = await User.query().findById(1); // Auto-loads posts, profile

// Can still override/add more:
final users = await User.query()
    .withRelations(['followers']) // Adds to default 'with'
    .get(); // Loads: posts, profile, followers

// Or disable default loading:
final users = await User.query()
    .without(['posts']) // Exclude from default
    .get(); // Only loads: profile
```

**Implementation:**
- Add `List<dynamic> get with => []` property to `KhademModel`
- Modify query builder `get()`, `first()`, `findById()` to auto-apply model's `with` relations
- Add `without()` method to exclude specific default relations
- Add `withOnly()` method to replace (not add to) default relations

---

#### 1.2 Direct Relation Accessors ⭐⭐⭐
**Goal:** Access relations as model properties

**Current:**
```dart
final posts = user.getRelation('posts') as List<Post>;
final author = post.getRelation('author') as User?;
```

**Desired:**
```dart
final posts = user.posts; // List<Post>
final author = post.author; // User?

// With lazy loading:
final posts = await user.posts; // Auto-loads if not loaded
```

**Implementation Strategy:**
- Add `defineRelationAccessors()` method to generate getters
- Support both sync (if loaded) and async (lazy load) access
- Use code generation or manual getter definitions

**Example:**
```dart
class User extends KhademModel<User> {
  // Manual relation accessors
  List<Post> get posts => getRelation('posts') ?? [];
  Profile? get profile => getRelation('profile');
  
  // With lazy loading
  Future<List<Post>> get postsAsync async {
    if (!isRelationLoaded('posts')) {
      await loadRelation('posts');
    }
    return posts;
  }
}
```

---

#### 1.3 Async Computed Properties ⭐⭐⭐
**Goal:** Support `Future<dynamic>` in computed properties

**Current:**
```dart
Map<String, dynamic> get computed => {
  'full_name': () => '$firstName $lastName',
  'age': () => DateTime.now().year - birthYear,
};
```

**Desired:**
```dart
Map<String, dynamic> get computed => {
  'full_name': () => '$firstName $lastName',
  'posts_count': () async => await posts.length,
  'display_name': () async {
    if (type == 'private') {
      final users = await loadRelation('users');
      return users.first.name;
    }
    return name;
  },
};
```

**Implementation:**
- Change `computed` return type to allow `Function` or `Future<dynamic> Function()`
- Update `_getComputedAttribute()` to handle async functions
- Update `toJson()` to await async computed properties

---

#### 1.4 Guarded and Protected Attributes ⭐⭐
**Goal:** Flexible mass assignment protection

**Current:** Only `fillable` (whitelist)

**Desired:**
```dart
class User extends KhademModel<User> {
  // Whitelist approach
  @override
  List<String> get fillable => ['name', 'email', 'password'];
  
  // Blacklist approach (more flexible)
  @override
  List<String> get guarded => ['id', 'email_verified_at', 'remember_token'];
  
  // Protected from serialization
  @override
  List<String> get protected => ['password', 'remember_token'];
}
```

**Rules:**
- If `fillable` is not empty, use whitelist (current behavior)
- If `fillable` is empty and `guarded` is not empty, use blacklist
- If both empty, allow all fields
- `protected` fields never included in `toJson()`, only in `toDatabaseJson()`

---

### Priority 2: Advanced Features

#### 2.1 Query Scopes ⭐⭐
**Goal:** Reusable query constraints

**Desired:**
```dart
class User extends KhademModel<User> {
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
}

// Usage:
final users = await User.query()
    .active()          // Applies scopeActive
    .verified()        // Applies scopeVerified
    .role('admin')     // Applies scopeRole
    .get();
```

**Implementation:**
- Add scope discovery mechanism
- Extend query builder to call scope methods
- Scope methods prefixed with `scope*` auto-register

---

#### 2.2 Soft Deletes ⭐⭐
**Goal:** Soft delete with `deleted_at` column

**Desired:**
```dart
class Post extends KhademModel<Post> with SoftDeletes {
  // Automatically adds deleted_at handling
}

// Usage:
await post.delete(); // Sets deleted_at, doesn't remove from DB
await post.forceDelete(); // Actually deletes from DB
await post.restore(); // Restores soft-deleted record

// Querying:
final posts = await Post.query().get(); // Excludes soft-deleted
final all = await Post.query().withTrashed().get(); // Includes soft-deleted
final trashed = await Post.query().onlyTrashed().get(); // Only soft-deleted
```

**Implementation:**
- Create `SoftDeletes` mixin
- Override `delete()` to set `deleted_at`
- Add `forceDelete()`, `restore()` methods
- Auto-add `whereNull('deleted_at')` to queries
- Add `withTrashed()`, `onlyTrashed()` query methods

---

#### 2.3 Timestamps ⭐⭐
**Goal:** Auto-manage `created_at` and `updated_at`

**Desired:**
```dart
class User extends KhademModel<User> with Timestamps {
  // Automatically handles created_at and updated_at
}

// Disable timestamps for specific model:
class Session extends KhademModel<Session> {
  @override
  bool get timestamps => false;
}

// Custom timestamp names:
class Post extends KhademModel<Post> with Timestamps {
  @override
  String get createdAtColumn => 'published_at';
  
  @override
  String get updatedAtColumn => 'modified_at';
}
```

**Implementation:**
- Create `Timestamps` mixin
- Auto-set `created_at` on insert
- Auto-set `updated_at` on update
- Add `touch()` method to update `updated_at` only
- Add `timestamps` boolean flag to disable

---

#### 2.4 Model Observers ⭐
**Goal:** Separate observer classes for model events

**Desired:**
```dart
class UserObserver {
  void creating(User user) {
    user.uuid = Uuid().v4();
  }
  
  void created(User user) {
    // Send welcome email
  }
  
  void updating(User user) {
    // Log changes
  }
  
  bool deleting(User user) {
    // Prevent deletion if user has posts
    if (user.posts.isNotEmpty) {
      return false; // Cancel delete
    }
    return true;
  }
}

// Register observer:
User.observe(UserObserver());
```

**Implementation:**
- Create `Observer` base class
- Add observer registration mechanism
- Call observer methods before/after events
- Support cancellation (return `false` to prevent)

---

#### 2.5 Advanced Attribute Casting ⭐
**Goal:** Custom casters, arrays, encrypted attributes

**Desired:**
```dart
class User extends KhademModel<User> {
  @override
  Map<String, Type> get casts => {
    'email_verified_at': DateTime,
    'settings': Json, // Cast to Map<String, dynamic>
    'roles': Array, // Cast to List<String>
    'metadata': JsonArray, // Cast to List<Map<String, dynamic>>
    'password': Encrypted, // Auto encrypt/decrypt
    'preferences': UserPreferences, // Custom caster
  };
}

// Custom caster:
class UserPreferencesCaster extends AttributeCaster<UserPreferences> {
  @override
  UserPreferences get(dynamic value) {
    return UserPreferences.fromJson(jsonDecode(value));
  }
  
  @override
  dynamic set(UserPreferences value) {
    return jsonEncode(value.toJson());
  }
}
```

---

#### 2.6 Relationship Count / Aggregates ⭐
**Goal:** Load relation counts without loading full relations

**Desired:**
```dart
// Eager load counts:
final users = await User.query()
    .withCount(['posts', 'comments'])
    .get();

print(users.first.postsCount); // Access count directly

// Load aggregates:
final users = await User.query()
    .withSum('orders', 'amount') // ordersAmountSum
    .withAvg('orders', 'rating')  // ordersRatingAvg
    .withMax('posts', 'views')    // postsViewsMax
    .get();

// Conditional counts:
final users = await User.query()
    .withCount({
      'posts': (q) => q.where('published', '=', true),
      'comments': (q) => q.where('approved', '=', true),
    })
    .get();
```

---

### Priority 3: Quality of Life Improvements

#### 3.1 Better Error Messages
- Add validation for missing relations
- Warn when accessing unloaded relations
- Provide helpful error messages for mass assignment violations

#### 3.2 Model Factory / Seeding Support
- Add model factories for testing
- Seed database with fake data

#### 3.3 Global Scopes
- Auto-apply scopes to all queries (e.g., tenant filtering)

#### 3.4 Attribute Mutators
- `setAttribute()` and `getAttribute()` hooks
- Transform data on get/set

#### 3.5 Dirty Tracking
- `isDirty()`, `getOriginal()`, `getChanges()`
- Track which attributes changed

---

## 📋 Implementation Plan

### Phase 1: Core Enhancements (Week 1)
1. ✅ Add model-level `defaultRelations` property for default eager loading *(COMPLETE - 2-3 hours)*
2. ⬜ Implement async computed properties *(2-3 hours)*
3. ⬜ Add guarded/protected attributes *(2 hours)*
4. ⬜ Create direct relation accessors pattern *(3-4 hours)*

### Phase 2: Advanced Features (Week 2)
5. ⬜ Implement query scopes *(4-5 hours)*
6. ⬜ Add soft deletes mixin *(3-4 hours)*
7. ⬜ Add timestamps mixin *(2-3 hours)*
8. ⬜ Create model observers *(4-5 hours)*

### Phase 3: Polish & Testing (Week 3)
9. ⬜ Advanced casting (Json, Array, Encrypted) *(4-5 hours)*
10. ⬜ Relationship counts/aggregates *(3-4 hours)*
11. ⬜ Comprehensive test suite *(8-10 hours)*
12. ⬜ Documentation and examples *(4-5 hours)*

**Total Estimated Time:** 40-50 hours

---

## 🔧 Technical Considerations

### Breaking Changes
- None if implemented carefully
- All enhancements should be backward compatible
- Existing `withRelations()` stays, `with()` is alias
- `fillable` behavior unchanged, `guarded` is additive

### Performance Impact
- Async computed properties: Minimal (only computed when accessed)
- Relation accessors: Zero overhead (just getters)
- Soft deletes: Small overhead (one WHERE clause)
- Timestamps: Minimal (set on save)

### Dependencies
- No new package dependencies required
- May add code generation package later for relation accessors

---

## 📝 Next Steps

1. **Review and approve** this enhancement plan
2. **Prioritize** which features to implement first
3. **Create feature branch**: `feature/model-enhancements`
4. **Implement Phase 1** core enhancements
5. **Write tests** for each feature
6. **Update documentation** with examples
7. **Merge to dev** and test in real applications

---

## 💡 Example: Enhanced Model

```dart
class ChatRoom extends KhademModel<ChatRoom> with SoftDeletes, Timestamps {
  late String? name;
  late String type; // 'private' or 'group'
  late int? ownerId;
  
  // Default relations to always eager load
  @override
  List<dynamic> get with => ['users.user', 'owner'];
  
  // Fillable (whitelist)
  @override
  List<String> get fillable => ['name', 'type', 'owner_id'];
  
  // Guarded (blacklist - alternative to fillable)
  @override
  List<String> get guarded => ['id', 'created_at', 'updated_at', 'deleted_at'];
  
  // Protected from JSON serialization
  @override
  List<String> get protected => ['deleted_at'];
  
  // Async computed properties
  @override
  Map<String, dynamic> get computed => {
    'display_name': () async => await _getDisplayName(),
    'users_count': () async => users.length, // users already loaded!
    'is_private': () => type == 'private',
  };
  
  // Direct relation accessors (no casting needed!)
  List<ChatRoomUser> get users => getRelation('users') ?? [];
  User? get owner => getRelation('owner');
  
  // Async relation accessors (with lazy loading)
  Future<List<ChatRoomUser>> get usersAsync async {
    if (!isRelationLoaded('users')) {
      await loadRelation('users');
    }
    return users;
  }
  
  // Relation definitions
  @override
  Map<String, RelationDefinition> get relations => {
    'users': RelationDefinition.hasMany(
      relatedTable: 'chat_room_users',
      foreignKey: 'chat_room_id',
      localKey: 'id',
      factory: () => ChatRoomUser(),
    ),
    'owner': RelationDefinition.belongsTo(
      relatedTable: 'users',
      foreignKey: 'id',
      localKey: 'owner_id',
      factory: () => User(),
    ),
  };
  
  // Query scopes
  QueryBuilderInterface<ChatRoom> scopePrivate(QueryBuilderInterface<ChatRoom> query) {
    return query.where('type', '=', 'private');
  }
  
  QueryBuilderInterface<ChatRoom> scopeForUser(
    QueryBuilderInterface<ChatRoom> query,
    int userId,
  ) {
    return query.whereHas('users', (q) {
      q.where('user_id', '=', userId);
    });
  }
  
  // Helper for display name
  Future<String> _getDisplayName() async {
    if (type == 'private' && name == null) {
      final roomUsers = await usersAsync;
      final otherUser = roomUsers.firstWhere(
        (u) => u.userId.toString() != RequestContext.userId,
        orElse: () => ChatRoomUser(),
      );
      
      if (!otherUser.isRelationLoaded('user')) {
        await otherUser.loadRelation('user');
      }
      
      return otherUser.user?.name ?? 'Private Chat';
    }
    return name ?? 'Group Chat';
  }
  
  @override
  ChatRoom newFactory(Map<String, dynamic> data) => ChatRoom()..fromJson(data);
}

// Usage examples:
void main() async {
  // Model's 'with' property auto-loads users.user and owner
  final rooms = await ChatRoom.query()
      .private() // Query scope
      .forUser(123) // Query scope with parameter
      .get(); // Auto-loads: users.user, owner
  
  final room = rooms.first;
  
  // Direct relation access (already loaded!)
  print(room.users.length); // No casting needed!
  print(room.owner?.name); // Type-safe
  
  // Async computed properties work with loaded relations
  print(await room.getComputedAttribute('display_name'));
  
  // Or access via appends
  final json = await room.append(['display_name', 'users_count']).toJson();
  print(json['display_name']);
  
  // Can exclude default relations if needed
  final lightRooms = await ChatRoom.query()
      .without(['users']) // Don't load users
      .get(); // Only loads: owner
  
  // Or load additional relations beyond defaults
  final roomsWithMessages = await ChatRoom.query()
      .withRelations(['messages']) // Adds to default 'with'
      .get(); // Loads: users.user, owner, messages
  
  // Soft delete
  await room.delete(); // Sets deleted_at
  await room.restore(); // Restores
  await room.forceDelete(); // Permanently deletes
  
  // Timestamps auto-managed
  print(room.createdAt);
  print(room.updatedAt);
}
```

---

**Status:** ✅ Phase 1-2 Complete | 🚧 Phase 3 In Progress  
**Current:** Implementing Advanced Features (Casting, Aggregates, Observers)  
**Completed:** Default Relations, Async Computed, Guarded/Protected, Relation Accessors, Query Scopes, Soft Deletes, Timestamps
